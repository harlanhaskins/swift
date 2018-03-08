import Foundation
import SwiftSyntax

public final class TrailingClosureRewriter: SyntaxRewriter {
  public override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
    // Ensures the closure has exactly one space before it.
    let adjustClosureTrivia: (ClosureExprSyntax) -> ClosureExprSyntax = {
      return $0.withLeftBrace(
        $0.leftBrace.withLeadingTrivia(
          $0.leftBrace.leadingTrivia.withOneSpace()))
    }

    // Simple case: foo() { _ in return } -> foo { _ in return }
    if let closure = node.trailingClosure, node.argumentList.count == 0 {
      return super.visit(node.withLeftParen(nil)
                             .withRightParen(nil)
                             .withTrailingClosure(adjustClosureTrivia(closure)))
    }

    // Complex case: foo({ _ in return }) -> foo { _ in return }
    guard node.argumentList.count == 1,
          let firstArg = node.argumentList.first,
          let closure = firstArg.expression as? ClosureExprSyntax else {
        return super.visit(node)
    }
    let newArgs = SyntaxFactory.makeFunctionCallArgumentList([
      firstArg.withExpression(adjustClosureTrivia(closure))
    ])
    return super.visit(node.withLeftParen(nil)
                           .withRightParen(nil)
                           .withArgumentList(newArgs))
  }
}
