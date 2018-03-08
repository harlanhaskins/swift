import Foundation
import SwiftSyntax

public final class ParenthesizedConditionRewriter: SyntaxRewriter {
  public override func visit(_ node: ConditionElementSyntax) -> Syntax {
    guard let tup = node.condition as? TupleExprSyntax,
          tup.elementList.count == 1 else {
      return node
    }

    let expr = tup.elementList.first!.expression

    // If the condition is a function with a trailing closure, removing the
    // outer set of parentheses introduces a parse ambiguity.
    if let fnCall = expr as? FunctionCallExprSyntax,
       fnCall.trailingClosure != nil {
      return node
    }

    let newExpr = ReplaceTriviaRewriter(
      lastToken: expr.lastToken,
      leadingTrivia: tup.leftParen.leadingTrivia,
      trailingTrivia: tup.rightParen.trailingTrivia
    ).visit(expr)
    return node.withCondition(newExpr)
  }
}
