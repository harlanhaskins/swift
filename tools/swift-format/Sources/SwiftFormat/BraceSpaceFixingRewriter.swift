import Foundation
import SwiftSyntax

/// Returns `true` if the containing syntax node that is allowed to be a
/// single-line braced node (currently closures and getters/setters), if the
/// node has only one statement.
func isInAllowedSingleLineContainer(_ token: TokenSyntax) -> Bool {
  if token.parent is AccessorBlockSyntax { return true }
  guard let container = token.containingExprStmtOrDecl else { return false }
  if let stmtContainer = container as? WithStatementsSyntax {
    guard stmtContainer.statements.count <= 1,
          stmtContainer is ClosureExprSyntax ||
          stmtContainer is AccessorDeclSyntax else {
      return false
    }
    return true
  } else if let block = token.parent as? CodeBlockSyntax {
    return block.statements.count <= 1
  }
  return false
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
      if !isInAllowedSingleLineContainer(token) {
        newLeadingTrivia = token.leadingTrivia.withOneLeadingNewline()
      }
      return token.withLeadingTrivia(newLeadingTrivia)
    }
    return token
  }
}
