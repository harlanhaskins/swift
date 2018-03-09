import Foundation
import SwiftSyntax

public final class TrailingClosureRewriter: SyntaxRewriter {
  public override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
    // Ensures the closure has exactly one space before it.
    let adjustClosureTrivia:
      (FunctionCallExprSyntax) -> FunctionCallExprSyntax = { node in
        let lastTok = node.calledExpression.lastToken
        return ReplaceTriviaRewriter(
          token: lastTok,
          leadingTrivia: lastTok?.leadingTrivia,
          trailingTrivia: lastTok?.trailingTrivia.withOneTrailingSpace()
        ).visit(node) as! FunctionCallExprSyntax
    }

    // Simple case: foo() { _ in return } -> foo { _ in return }
    if node.trailingClosure != nil && node.argumentList.count == 0 {
      return super.visit(adjustClosureTrivia(node.withLeftParen(nil)
                                                 .withRightParen(nil)))
    }

    // Complex case: foo({ _ in return }) -> foo { _ in return }
    guard node.argumentList.count == 1,
          let firstArg = node.argumentList.first,
          firstArg.label == nil,
          let closure = firstArg.expression as? ClosureExprSyntax,
          !(node.parent is ConditionElementSyntax) else {
      return super.visit(node)
    }

    let adjustedClosure =
      ReplaceTriviaRewriter(
        token: closure.lastToken,
        trailingTrivia: node.rightParen?.trailingTrivia
    ).visit(closure) as! ClosureExprSyntax

    return super.visit(
      adjustClosureTrivia(node.withLeftParen(nil)
                              .withRightParen(nil)
                              .withArgumentList(nil)
                              .withTrailingClosure(adjustedClosure)))
  }
}
