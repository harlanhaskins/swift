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
#include "swift/AST/Initializer.h"
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

static StringRef nameForLOLCodeOp(tok token, bool isBothSaem) {
  StringRef ret;
  switch (token) {
  #define FUNC_MAP(TOK, SUFFIX) \
    case tok::kw_##TOK: \
      return "__lolcode_" #SUFFIX;
  FUNC_MAP(SUM, sum)
  FUNC_MAP(DIFF, diff)
  FUNC_MAP(PRODUKT, produkt)
  FUNC_MAP(QUOSHUNT, quoshunt)
  FUNC_MAP(MOD, mod)
  FUNC_MAP(BIGGR, biggr)
  FUNC_MAP(SMALLR, smallr)
  FUNC_MAP(EITHER, either)
  FUNC_MAP(WON, won_of)
  FUNC_MAP(ANY, any_of)
  FUNC_MAP(ALL, all_of)
  FUNC_MAP(DIFFRINT, diffrint)
  FUNC_MAP(SMOOSH, smoosh)
  FUNC_MAP(NOT, not)
  FUNC_MAP(VISIBLE, visible)
  FUNC_MAP(GIMMEH, gimmeh)
  #undef FUNC_MAP
  case tok::BOTH:
    return isBothSaem ? "_lolcode_both_saem" : "_lolcode_both_of";
  default:
    llvm_unreachable("invalid lolcode op");
  }
}

static CallExpr *makeLOLCodeCall(ASTContext &C, tok lolcodeOp, bool isBothSaem,
  SourceLoc loc, const SmallVectorImpl<Expr *> &args) {
  auto name = nameForLOLCodeOp(lolcodeOp, isBothSaem);
  DeclNameLoc()
  auto declRef = new (C) UnresolvedDeclRefExpr(
    C.getIdentifier(funcName), DeclRefKind::Ordinary, DeclNameLoc());
  auto args = TupleExpr(SourceLoc(), args, {}, {},
                        SourceLoc(), false, true, Type());
  return new (C) CallExpr(declRef, args, true, {}, {}, false, Type());
}

ParserStatus Parser::parseLOLCodeParameters(SmallVectorImpl<Expr *> &Exprs) {
  while (true) {
    ParserResult<Expr> result = parseLOLCodeExpr();
    if (result.isNull()) return makeParserError();
    Exprs.push_back(result.get());

    if (!consumeIf(tok::kw_AN)) break;
  }
  if (!consumeIf(tok::kw_MKAY)) break;
  return makeParserSuccess();
}

ParserStatus parseBinaryLOLCodeArguments(
  Parser &P, SmallVectorImpl<Expr *> &exprs) {
    auto lhs = P.parseLOLCodeExpr();
    if (lhs.isNull()) return P.makeParserError();
    args.push_back(lhs.get());

    if (!P.consumeIf(tok::kw_AN)) {
      P.diagnose(Tok, diag::expected_expr_lolcode);
      return P.makeParserError();
    }

    auto rhs = P.parseLOLCodeExpr();
    if (rhs.isNull()) return P.makeParserError();
    args.push_back(rhs.get());

    return P.makeParserSuccess()
}

ParserResult<Expr> Parser::parseLOLCodeBuiltinOpExpr() {
  tok kind = Tok.getKind();
  SmallVector<Expr *, 5> args;
  SourceLoc loc = consumeToken();
  bool isBothSaem = false;

  switch (kind) {
  // Unary operator
  case tok::kw_NOT: {
    auto expr = parseLOLCodeExpr();
    if (expr.isNull()) return makeParserError();
    args.push_back(expr.get());
    break;
  }

  // Binary operators
  case tok::kw_BIGGR:
  case tok::kw_SMALLR:
  case tok::kw_EITHER:
  case tok::kw_WON:
  case tok::kw_SUM:
  case tok::kw_DIFF:
  case tok::kw_PRODUKT:
  case tok::kw_QUOSHUNT:
  case tok::kw_MOD: {
    if (!consumeIf(tok::kw_OF)) {
      diagnose(Tok, diag::expected_expr_lolcode);
      return makeParserError();
    }
    LLVM_FALLTHROUGH;
  case tok::kw_DIFFRINT:
    auto result = parseBinaryLOLCodeArguments(*this, exprs);
    if (!result) return makeParserError();
    break;
  }
  case tok::kw_BOTH:
    if (consumeIf(tok::kw_SAEM)) {
      isBothSaem = true;
    } else if (consumeIf(tok::kw_OF)) {
      /* do nothing */
    } else {
      diagnose(Tok, diag::expected_expr_lolcode);
      return makeParserError();
    }
    auto result = parseBinaryLOLCodeArguments(*this, exprs);
    if (!result) return makeParserError();
    break;
  case tok::kw_ANY:
  case tok::kw_ALL:
    if (!consumeIf(tok::kw_OF)) {
      diagnose(Tok, diag::expected_expr_lolcode);
      return makeParserError();
    }
    LLVM_FALLTHROUGH;
  case tok::kw_SMOOSH: {
    auto result = parseLOLCodeParameters(args);
    if (!result) return makeParserError();
  }
  default:
    llvm_unreachable("not at start of lolcode builtin op")
  }
  return makeParserResult(makeLOLCodeCall(kind, isBothSaem, loc, args));
}

ParserResult<Expr> Parser::parseLOLCodeExpr() {
  switch (Tok.getKind()) {
  case tok::integer_literal: {
    StringRef Text = Tok.getText();
    SourceLoc Loc = consumeToken(tok::integer_literal);
    ExprContext.setCreateSyntax(SyntaxKind::IntegerLiteralExpr);
    return makeParserResult(new (Context)
                                IntegerLiteralExpr(Text, Loc,
                                                   /*Implicit=*/false));
  }
  case tok::floating_literal: {
    StringRef Text = Tok.getText();
    SourceLoc Loc = consumeToken(tok::floating_literal);
    ExprContext.setCreateSyntax(SyntaxKind::FloatLiteralExpr);
    return makeParserResult(new (Context) FloatLiteralExpr(Text, Loc,
                                                           /*Implicit=*/false));
  }

  case tok::string_literal:  // "foo"
    return parseExprStringLiteral();

  case tok::kw_WIN:
  case tok::kw_FAIL: {
    ExprContext.setCreateSyntax(SyntaxKind::BooleanLiteralExpr);
    bool isTrue = Tok.is(tok::kw_WIN);
    return makeParserResult(new (Context)
                                BooleanLiteralExpr(isTrue, consumeToken()));
  }

  case tok::identifier:  // foo
    return makeParserResult(parseExprIdentifier());

  // Eat an invalid token in an expression context.  Error tokens are diagnosed
  // by the lexer, so there is no reason to emit another diagnostic.
  case tok::unknown:
    consumeToken(tok::unknown);
    return makeParserError;

  case tok::kw_BOTH:
    if (!peekToken().is(tok::kw_SAEM)) {
      diagnose(Tok, diag::expected_expr_lolcode);
      return makeParserError();
    }
    return makeParserResult(parseLOLCodeBuiltinOpExpr());
  case tok::kw_SUM:
  case tok::kw_DIFF:
  case tok::kw_PRODUKT:
  case tok::kw_QUOSHUNT:
  case tok::kw_MOD:
  case tok::kw_BIGGR:
  case tok::kw_SMALLR:
  case tok::kw_EITHER:
  case tok::kw_WON:
  case tok::kw_ANY:
  case tok::kw_ALL:
    if (!peekToken().is(tok::kw_OF)) {
      diagnose(Tok, diag::expected_expr_lolcode);
      return makeParserError;
    }
    LLVM_FALLTHROUGH;
  case tok::kw_DIFFRINT:
  case tok::kw_SMOOSH:
  case tok::kw_NOT:
    return makeParserResult(parseLOLCodeBuiltinOpExpr());

  default:
    checkForInputIncomplete();
    diagnose(Tok, diag::expected_expr_lolcode);
    return makeParserError;
  }
}

ParserResult<Expr> Parser::parseLOLCodePrintStmtNode() {
  consumeToken(tok::kw_VISIBLE);

  SmallVector<Expr *, 16> PrintExprs;
	do {
    ASTNode Result;
    ParserResult<Expr> ExprResult = parseLOLCodeExpr();
    if (auto *Expr = ExprResult.getPtrOrNull())
      PrintExprs.push_back(Expr);

    consumeIf(tok::kw_AN);
  } while (!Tok.isAtStartOfLine() && !(Tok.is(tok::oper_binary_spaced) && Tok.getText() == "!"));

  bool endsWithNewline = true;
  if (consumeIf(tok::oper_binary_spaced)) {
    endsWithNewline = false;
  }

  if (!Tok.isAtStartOfLine()) {
    return makeParserError();
  }

  UnresolvedDeclRefExpr *PrintRef
      = new (Context) UnresolvedDeclRefExpr(Context.getIdentifier("print"),
                                            DeclRefKind::Ordinary,
                                            DeclNameLoc());
  CallExpr *CE = CallExpr::createImplicit(Context, PrintRef, PrintExprs, {});
  return makeParserResult(CE);
}

ParserResult<Decl> Parser::parseLOLCodeDeclarationStmtNode(VarDecl *&VD) {
  TopLevelCodeDecl *topLevelDecl = nullptr;
  if (allowTopLevelCode() && CurDeclContext->isModuleScopeContext()) {
    // The body of topLevelDecl will get set later.
    topLevelDecl = new (Context) TopLevelCodeDecl(CurDeclContext);
  }

  SourceLoc HasLoc = consumeToken(tok::kw_HAZ);
  consumeToken();

  Identifier name;
  SourceLoc loc = consumeIdentifier(&name);
  if (Tok.isIdentifierOrUnderscore() && !Tok.isContextualDeclKeyword())
    diagnoseConsecutiveIDs(name.str(), loc, "variable");

  Pattern *varPat = createBindingFromPattern(loc, name,
                                             VarDecl::Specifier::Var);
  VD = varPat->getSingleVar();
  Expr *PatternInit = nullptr;
  if (consumeIf(tok::kw_ITZ) && consumeIf(tok::kw_A)) {
    SyntaxParsingContext InitCtx(SyntaxContext, SyntaxKind::InitializerClause);
    PatternBindingInitializer *initContext = nullptr;

    ParserResult<Expr> init = parseLOLCodeExpr();

    // Remember this init for the PatternBindingDecl.
    PatternInit = init.getPtrOrNull();

    if (!CurDeclContext->isLocalContext() && !topLevelDecl)
      initContext = new (Context) PatternBindingInitializer(CurDeclContext);

    // If we are doing second pass of code completion, we don't want to
    // suddenly cut off parsing and throw away the declaration.
    if (init.hasCodeCompletion() && isCodeCompletionFirstPass()) {

      // Register the end of the init as the end of the delayed parsing.
      DelayedDeclEnd
        = init.getPtrOrNull() ? init.get()->getEndLoc() : SourceLoc();
      return makeParserCodeCompletionStatus();
    }

    if (init.isNull())
      return makeParserError();
  }

  TypedPattern *pattern
      = new (Context) TypedPattern(varPat,
                                   TypeLoc::withoutLoc(Context.TheAnyType));
  addPatternVariablesToScope(pattern);

//  /* Check for an optional type initialization */
//  else if (acceptToken(&tokens, TT_ITZA)) {
//    /* Parse the type to initialize to */
//    type = parseTypeNode(&tokens);
//    if (!type) goto parseDeclarationStmtNodeAbort;
//  }
//  /* Check for an optional array inheritance */
//  else if (acceptToken(&tokens, TT_ITZLIEKA)) {
//    /* Parse the parent to inherit from */
//    parent = parseIdentifierNode(&tokens);
//    if (!parent) goto parseDeclarationStmtNodeAbort;
//  }

  if (!Tok.isAtStartOfLine()) {
    return makeParserError();
  }

  // Now that we've parsed all of our patterns, initializers and accessors, we
  // can finally create our PatternBindingDecl to represent the
  // pattern/initializer pairs.
  auto PBD = PatternBindingDecl::create(Context, SourceLoc(),
                                        StaticSpellingKind::None,
                                        HasLoc, pattern, PatternInit,
                                        CurDeclContext);

  // If we're setting up a TopLevelCodeDecl, configure it by setting up the
  // body that holds PBD and we're done.  The TopLevelCodeDecl is already set
  // up in Decls to be returned to caller.
  if (topLevelDecl) {
    PBD->setDeclContext(topLevelDecl);
    auto range = PBD->getSourceRange();
    topLevelDecl->setBody(BraceStmt::create(Context, range.Start,
                                            ASTNode(PBD), range.End, true));
    return makeParserResult(PBD);
  }

  // Always return the result for PBD.
  return makeParserResult(PBD);
}

ParserResult<Expr> Parser::parseLOLCodeCastStmtNode() {
  SourceLoc ISLoc = consumeToken(tok::kw_IS);
  consumeToken(tok::kw_NOW);
  consumeToken(tok::kw_A);

  ParserResult<TypeRepr> type = parseType(diag::expected_type_after_is);
  if (type.isNull())
    return nullptr;

  if (!Tok.isAtStartOfLine()) {
    return makeParserError();
  }
  return makeParserResult(new (Context) CoerceExpr(ISLoc, type.get()));
}

ParserStatus Parser::parseLOLCodeStmt(ASTNode &Node, VarDecl *&VD) {
  if (Tok.is(tok::identifier)) {
    Identifier Name;
    SourceLoc NameLoc;
    if (parseIdentifier(Name, NameLoc,
                        diag::expected_generics_parameter_name)) {
      return makeParserError();
    }

    if (Tok.is(tok::kw_IS) && peekToken().is(tok::kw_NOW)) {
      ParserResult<Expr> Res = parseLOLCodeCastStmtNode();
      if (Res.isNonNull())
        Node = Res.get();
    } /*else if (Tok.is(tok::kw_R)) {
      ParserResult<Decl> Res = parseLOLCodeAssignmentStmtNode();
      if (Res.isNonNull())
        Node = Res.get();
    } */else if (Tok.is(tok::kw_HAZ) && peekToken().isAny(tok::kw_AN, tok::kw_A)) {
      ParserResult<Decl> Res = parseLOLCodeDeclarationStmtNode(VD);
      if (auto *PBD = dyn_cast_or_null<PatternBindingDecl>(Res.getPtrOrNull())) {
        Node = PBD;
      }
    } /*else if (Tok.is(tok::kw_R) && peekToken().is(tok::kw_NOOB)) {
      consumeToken();
      consumeToken();
    } else {
      Node = parseExprNode();
      if (!Tok.isAtStartOfLine()) {
        Result.setIsParseError();
//        diagnose(Node.getStartLoc(), diag::line)
      }
    }*/
  } else if (Tok.is(tok::kw_VISIBLE)) {
    ParserResult<Expr> Res = parseLOLCodePrintStmtNode();
    if (Res.isNonNull())
      Node = Res.get();
  }/* else if (Tok.is(tok::kw_GIMMEH)) {
		Node = parseInputStmtNode();
  } else if (Tok.is(tok::kw_O) && peekToken().is(tok::kw_RLY)) {
		Node = parseIfThenElseStmtNode();
	} else if (Tok.is(tok::kw_WTF)) {
		ret = parseSwitchStmtNode();
	} else if (Tok.is(tok::kw_GTFO)) {
		ret = parseBreakStmtNode();
  } else if (Tok.is(tok::kw_FOUND) && peekToken().is(tok::kw_YR)) {
		ret = parseReturnStmtNode();
	} else if (Tok.is(tok::kw_IM) && peekToken().is(tok::kw_IN)) {
		ret = parseLoopStmtNode();
  } else if (Tok.is(tok::kw_HOW) && peekToken().is(tok::kw_IZ)) {
		ret = parseFuncDefStmtNode();
  } else if (Tok.is(tok::kw_O) && peekToken().is(tok::kw_HAI)) {
		ret = parseAltArrayDefStmtNode();
	}*/
//  /* Bare expression */
//  else if ((expr = parseExprNode(&tokens))) {
//    int status;
//
//    /* The expression should appear on its own line */
//    status = acceptToken(&tokens, TT_NEWLINE);
//    if (!status) {
//      parser_error(PR_EXPECTED_END_OF_EXPRESSION, tokens);
//      deleteExprNode(expr);
//      return NULL;
//    }
//
//    /* Create the new StmtNode structure */
//    ret = createStmtNode(ST_EXPR, expr);
//    if (!ret) {
//      deleteExprNode(expr);
//      return NULL;
//    }
//
//    /* Since we're successful, update the token stream */
//    *tokenp = tokens;
//  }
  return makeParserSuccess();
}

ParserStatus Parser::parseLOLCodeScript(SmallVectorImpl<ASTNode> &Entries) {
  while (!Tok.isAny(tok::kw_KTHXBYE, tok::kw_OIC, tok::kw_YA,
                    tok::kw_NO, tok::kw_MEBBE, tok::kw_OMG,
                    tok::kw_OMGWTF, tok::kw_IM, tok::kw_IF,
                    tok::kw_KTHX, tok::r_paren)) {
    ASTNode Result;
    VarDecl *VD = nullptr;
    ParserStatus Status = parseLOLCodeStmt(Result, VD);
    if (Status.isSuccess() && !Result.isNull()) {
      Entries.push_back(Result);
      if (auto *VarDecl = VD) {
        Entries.push_back(VarDecl);
      }
    }
  }
  return makeParserSuccess();
}

ParserResult<Expr> Parser::parseLOLCodeShedExpr() {
  Scope S(this, ScopeKind::Brace);
  SourceLoc CurrentLoc = Tok.getLoc();
  TypeLoc closureResultTy = TypeLoc::withoutLoc(Context.TheAnyType);
  auto params = ParameterList::createEmpty(Context);
  unsigned discriminator = CurLocalContext->claimNextClosureDiscriminator();
  ClosureExpr *closure =
    new (Context) ClosureExpr(params, SourceLoc(), CurrentLoc, SourceLoc(),
                              closureResultTy, discriminator, CurDeclContext);
  ContextChange CC(*this, closure);


  SmallVector<ASTNode, 16> ScriptItems;
  ParserStatus bodyStatus = parseLOLCodeScript(ScriptItems);
  if (bodyStatus.isError()) {
    return makeParserError();
  }
  TupleExpr *returnVal = TupleExpr::createEmpty(Context, SourceLoc(),
                                               SourceLoc(), /*implicit*/true);
  CoerceExpr *coerceRetValExpr
    = new (Context) CoerceExpr(returnVal, SourceLoc(),
                               TypeLoc::withoutLoc(Context.TheAnyType));
  ReturnStmt *LastStmt = new (Context) ReturnStmt(SourceLoc(),
                                                  coerceRetValExpr);
  ScriptItems.push_back(LastStmt);
  closure->setImplicit();
  BraceStmt *scriptBody = BraceStmt::create(Context, SourceLoc(),
                                            ScriptItems, SourceLoc());
  closure->setBody(scriptBody, /*isSingleExpression*/false);
  ApplyExpr *apply = CallExpr::createImplicit(Context, closure,
                                              {}, {});
  return makeParserResult(apply);
}

