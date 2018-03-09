import Foundation
import SwiftSyntax

/// Returns the containing syntax node that is allowed to be a single-line
/// braced node (currently closures and getters/setters), if the node has only
/// one statement.
func allowedSingleLineContainer(_ token: TokenSyntax) -> Syntax? {
  guard let container = token.containingExprStmtOrDecl else { return nil }
  guard let stmtContainer = container as? WithStatementsSyntax else {
    return nil
  }
  guard stmtContainer.statements.count <= 1 else { return nil }
  if stmtContainer is ClosureExprSyntax ||
     stmtContainer is AccessorDeclSyntax ||
     stmtContainer is DeferStmtSyntax {
    return container
  }
  return nil
}

public final class BraceSpaceFixingRewriter: SyntaxRewriter {
  public override func visit(_ token: TokenSyntax) -> Syntax {
    let next = token.nextToken
    if let n = next, n.tokenKind == .leftBrace {
      return token.withTrailingTrivia(
        token.trailingTrivia.withOneTrailingSpace())
    }

    if token.tokenKind == .leftBrace {
      return token.withLeadingTrivia(
        token.leadingTrivia.withoutSpaces().withoutNewlines())
    }

    if token.tokenKind == .rightBrace {
      var newLeadingTrivia = token.leadingTrivia
      if allowedSingleLineContainer(token) == nil {
        newLeadingTrivia = token.leadingTrivia.withOneLeadingNewline()
      }
      return token.withLeadingTrivia(newLeadingTrivia)
    }
    return token
  }
}
