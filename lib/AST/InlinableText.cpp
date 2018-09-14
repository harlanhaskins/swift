//===---- InlinableText.cpp - Extract inlinable source text -----*- C++ -*-===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
#include "InlinableText.h"
#include "swift/AST/ASTContext.h"
#include "swift/AST/ASTWalker.h"
#include "swift/AST/ASTNode.h"
#include "swift/AST/Decl.h"
#include "swift/AST/Expr.h"
#include "swift/AST/PrettyStackTrace.h"
#include "swift/Parse/Lexer.h"
#include "swift/Parse/Parser.h"
#include "swift/Syntax/Trivia.h"
#include "swift/Syntax/TokenSyntax.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/SmallString.h"

using namespace swift;
using namespace syntax;

/// Moves the comments in the provided iterator to the end, and returns a
/// pointer to the first comment.
static TriviaList::iterator
removeComments(TriviaList::iterator begin, TriviaList::iterator end) {
  return std::remove_if(begin, end, [](const TriviaPiece &piece) {
                                      return piece.isComment();
                                    });
}

/// Removes all comments from the provided input.
static void removeComments(TriviaList &input) {
  input.erase(removeComments(input.begin(), input.end()), input.end());
}

/// Determines if a given trivia piece is a newline.
static bool isNewline(const TriviaPiece &piece) {
  switch (piece.getKind()) {
  case TriviaKind::Newline:
  case TriviaKind::CarriageReturn:
  case TriviaKind::CarriageReturnLineFeed:
    return true;
  default: return false;
  }
}

/// Finds the last element in the provided bidirectional iterator that satisfies
/// the provided predicate.
template <typename Iterator, typename Predicate>
static Iterator
find_last_if(const Iterator begin, const Iterator end, Predicate pred) {
  for (auto it = end; it != begin; --it) {
    if (pred(*it))
      return it;
  }
  return end;
}


/// Returns an iterator pointing to the last newline in the input list, or the
/// end of the input if none is found.
static TriviaList::iterator
indexOfLastNewline(TriviaList &input) {
  return find_last_if(input.begin(), input.end(),
                      [](const TriviaPiece &piece) {
                        return isNewline(piece);
                      });
}

/// Removes all comments in the input list, treating it as leading trivia.
static void removeLeadingComments(TriviaList &input) {
  // The strategy here is to choose a pivot point.
  // If there are no newlines in this trivia, then remove all comments, but
  // preserve all whitespace.
  // Otherwise, pick the last newline, remove _all_ trivia before it, and
  // then remove all comments after it, preserving the whitespace.
  auto it = indexOfLastNewline(input);
  if (it == input.end()) {
    removeComments(input);
    return;
  }

  input.erase(input.begin(), it);
  input.erase(removeComments(it, input.end()),
              input.end());
}

/// Removes all comments in the input list, treating it as trailing trivia.
static void removeTrailingComments(TriviaList &input) {
  // Trailing block comments can not be safely removed, otherwise you might
  // paste two tokens together, instead they have to be replaced
  // with a single space.
  for (auto it = input.begin(); it != input.end(); ++it) {
    if (it->getKind() == TriviaKind::BlockComment ||
        it->getKind() == TriviaKind::DocBlockComment) {
      *it = TriviaPiece::space();
    }
  }

  // Trailing line comments can just be removed.
  auto removedEnd = std::remove_if(
                      input.begin(), input.end(),
                      [](TriviaPiece &p) {
                        return p.getKind() == TriviaKind::LineComment ||
                               p.getKind() == TriviaKind::DocLineComment;
                      });
  input.erase(removedEnd, input.end());
}

/// Removes all comments from the provided Swift source text, storing the
/// result in the provided scratch buffer.
static
StringRef removeComments(StringRef text, SmallVectorImpl<char> &scratch) {
  // Copy the source into a temporary source manager buffer.
  SourceManager sourceManager;
  unsigned bufferID = sourceManager.addMemBufferCopy(text);
  auto tokensAndPositions = tokenizeWithTrivia({}, sourceManager, bufferID);

  // For each token, remove comments from the leading and trailing trivia, and
  // form new tokens without comments.
  SmallVector<RC<RawSyntax>, 128> finalTokens;
  for (auto &pair : tokensAndPositions) {
    auto tok = pair.first;
    TriviaList leading = tok->getLeadingTrivia().vec();
    removeLeadingComments(leading);
    TriviaList trailing = tok->getTrailingTrivia().vec();
    removeTrailingComments(trailing);
    finalTokens.push_back(tok->withLeadingTrivia(leading)
                             ->withTrailingTrivia(trailing));
  }

  // Print the token text to the scratch buffer.
  llvm::raw_svector_ostream os(scratch);
  SyntaxPrintOptions opts;
  for (auto tok : finalTokens) {
    tok->print(os, opts);
  }

  return { scratch.data(), scratch.size() };
}

/// Gets the last token that exists inside this IfConfigClause, ignoring
/// hoisted elements.
///
/// If the clause is the last element, this returns the beginning of the line
/// before the parent IfConfigDecl's #endif token. Otherwise, it's the beginning
/// of the line before the next clause's #else or #elseif token.
static SourceLoc
getEffectiveEndLoc(SourceManager &sourceMgr, const IfConfigClause *clause,
                   const IfConfigDecl *decl) {
  auto clauses = decl->getClauses();
  if (clause == &clauses.back())
    return Lexer::getLocForStartOfLine(sourceMgr, decl->getEndLoc());

  assert(clause >= clauses.begin() && clause < clauses.end() &&
         "clauses must be contiguous");

  auto *nextClause = clause + 1;
  return Lexer::getLocForStartOfLine(sourceMgr, nextClause->Loc);
}

namespace {
/// A walker that searches through #if declarations, finding all text that does
/// not contribute to the final evaluated AST.
///
/// For example, in the following code:
/// ```
/// #if true
/// print("true")
/// #else
/// print("false")
/// #endif
/// ```
/// ExtractInactiveRanges will return the ranges (with leading newlines) of:
/// ```
/// #if true
/// #else
/// print("false")
/// #endif
/// ```
/// Leaving behind just 'print("true")'s range.
struct ExtractInactiveRanges : public ASTWalker {
  SmallVector<CharSourceRange, 4> ranges;
  SourceManager &sourceMgr;

  explicit ExtractInactiveRanges(SourceManager &sourceMgr)
    : sourceMgr(sourceMgr) {}

  /// Adds the two SourceLocs as a CharSourceRange to the set of ignored
  /// ranges.
  /// \note: This assumes each of these locs is a character location, not a
  ///        token location.
  void addRange(SourceLoc start, SourceLoc end) {
    auto charRange = CharSourceRange(sourceMgr, start, end);
    ranges.push_back(charRange);
  }

  bool walkToDeclPre(Decl *d) {
    auto icd = dyn_cast<IfConfigDecl>(d);
    if (!icd) return true;

    auto start = Lexer::getLocForStartOfLine(sourceMgr, icd->getStartLoc());
    auto end = Lexer::getLocForEndOfLine(sourceMgr, icd->getEndLoc());

    auto clause = icd->getActiveClause();

    // If there's no active clause, add the entire #if...#endif block.
    if (!clause) {
      addRange(start, end);
      return false;
    }

    // Ignore range from beginning of '#if', '#elseif', or '#else' to the
    // beginning of the elements of this clause.
    auto elementsBegin = clause->Loc;
    // If there's a condition (e.g. this isn't a '#else' block), then ignore
    // everything up to the end of the condition.
    if (auto cond = clause->Cond) {
      elementsBegin = cond->getEndLoc();
    }
    addRange(start, Lexer::getLocForEndOfLine(sourceMgr, elementsBegin));

    // Ignore range from effective end of the elements of this clause to the
    // end of the '#endif'
    addRange(getEffectiveEndLoc(sourceMgr, clause, icd), end);

    // Walk into direct children of this node that are IfConfigDecls, because
    // the standard walker won't walk into them.
    for (auto &elt : clause->Elements)
      if (elt.isDecl(DeclKind::IfConfig))
        elt.get<Decl *>()->walk(*this);

    return false;
  }

  /// Gets the ignored ranges in source order.
  ArrayRef<CharSourceRange> getSortedRanges() {
    std::sort(ranges.begin(), ranges.end(),
              [&](CharSourceRange r1, CharSourceRange r2) {
                assert(!r1.overlaps(r2) && "no overlapping ranges");
                return sourceMgr.isBeforeInBuffer(r1.getStart(), r2.getStart());
              });
    return ranges;
  }
};
} // end anonymous namespace

StringRef swift::extractInlinableText(ASTContext &ctx, ASTNode node,
                                      SmallVectorImpl<char> &scratch) {
  PrettyStackTraceLocation pst(ctx, "extracting inlinable text",
                               node.getStartLoc());

  auto &sourceMgr = ctx.SourceMgr;

  // Extract inactive ranges from the text of the node.
  ExtractInactiveRanges extractor(sourceMgr);
  node.walk(extractor);

  // If there were no inactive ranges, then there were no #if configs.
  // Return an unowned buffer directly into the source file.
  if (extractor.ranges.empty()) {
    auto range =
      Lexer::getCharSourceRangeFromSourceRange(
        sourceMgr, node.getSourceRange());
    return removeComments(sourceMgr.extractText(range), scratch);
  }

  // Begin piecing together active code ranges.

  SmallString<128> buf;

  // Get the full start and end of the provided node, as character locations.
  SourceLoc start = node.getStartLoc();
  SourceLoc end = Lexer::getLocForEndOfToken(sourceMgr, node.getEndLoc());
  for (auto &range : extractor.getSortedRanges()) {
    // Add the text from the current 'start' to this ignored range's start.
    auto charRange = CharSourceRange(sourceMgr, start, range.getStart());
    auto chunk = sourceMgr.extractText(charRange);
    buf.append(chunk);

    // Set 'start' to the end of this range, effectively skipping it.
    start = range.getEnd();
  }

  // If there's leftover unignored text, add it.
  if (start != end) {
    auto range = CharSourceRange(sourceMgr, start, end);
    auto chunk = sourceMgr.extractText(range);
    buf.append(chunk);
  }
  return removeComments(buf.str(), scratch);
}
