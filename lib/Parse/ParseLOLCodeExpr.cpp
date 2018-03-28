//===--- ParseExpr.cpp - Swift Language Parser for Expressions ------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
//
// LOLCode Expression Parsing and AST Building
//
//===----------------------------------------------------------------------===//

#include "swift/Parse/Parser.h"
#include "swift/AST/DiagnosticsParse.h"
#include "swift/Basic/EditorPlaceholder.h"
#include "swift/Parse/CodeCompletionCallbacks.h"
#include "swift/Parse/SyntaxParsingContext.h"
#include "swift/Syntax/SyntaxBuilders.h"
#include "swift/Syntax/SyntaxFactory.h"
#include "swift/Syntax/TokenSyntax.h"
#include "llvm/ADT/SmallString.h"
#include "llvm/ADT/StringSwitch.h"
#include "llvm/ADT/Twine.h"
#include "swift/Basic/Defer.h"
#include "swift/Basic/StringExtras.h"
#include "llvm/Support/Compiler.h"
#include "llvm/Support/SaveAndRestore.h"
#include "llvm/Support/raw_ostream.h"

using namespace swift;
using namespace swift::syntax;

ParserResult<Stmt> Parser::parseLOLCodeStmtItems(SmallVectorImpl<Stmt> &STs) {
  // Note that we're parsing a statement.
  StructureMarkerRAII ParsingStmt(*this, Tok.getLoc(),
                                  StructureMarkerKind::Statement);
  return nullptr;
}

ParserResult<Expr> Parser::parseLOLCodeScript() {
  while (!peekToken().isAny(tok::kw_KTHXBYE, tok::kw_OIC, tok::kw_YA,
                            tok::kw_NO, tok::kw_MEBBE, tok::kw_OMG,
                            tok::kw_OMGWTF, tok::kw_IM, tok::kw_IF,
                            tok::kw_KTHX)) {

  }
}

ParserResult<Expr> Parser::parseLOLCodeExpr() {
  SourceLoc HAILoc = consumeToken(tok::kw_HAI);

  auto body = parseLOLCodeScript();

  SourceLoc KTHXLoc = consumeToken(tok::kw_KTHX);
  SourceLoc BAILoc = consumeToken(tok::kw_BAI);

  return nullptr;
}

