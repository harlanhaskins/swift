import Foundation
import SwiftSyntax

public final class ParenthesizedConditionRewriter: SyntaxRewriter {
  public func extractExpr(_ tuple: TupleExprSyntax) -> ExprSyntax {
    assert(tuple.elementList.count == 1)
    let expr = tuple.elementList.first!.expression

    // If the condition is a function with a trailing closure, removing the
    // outer set of parentheses introduces a parse ambiguity.
    if let fnCall = expr as? FunctionCallExprSyntax,
      fnCall.trailingClosure != nil {
      return tuple
    }

    return ReplaceTriviaRewriter(
      token: expr.lastToken,
      leadingTrivia: tuple.leftParen.leadingTrivia,
      trailingTrivia: tuple.rightParen.trailingTrivia
    ).visit(expr) as! ExprSyntax
  }

  public override func visit(_ node: IfStmtSyntax) -> StmtSyntax {
    let conditions = visit(node.conditions) as! ConditionElementListSyntax
    return
      node.withIfKeyword(node.ifKeyword.withOneTrailingSpace())
          .withConditions(conditions)
  }

  public override func visit(_ node: ConditionElementSyntax) -> Syntax {
    guard let tup = node.condition as? TupleExprSyntax,
          tup.elementList.count == 1 else {
        return node
    }
    return node.withCondition(extractExpr(tup))
  }

  /// FIXME(hbh): Parsing for SwitchStmtSyntax is not implemented.
  public override func visit(_ node: SwitchStmtSyntax) -> StmtSyntax {
    guard let tup = node.expression as? TupleExprSyntax,
          tup.elementList.count == 1 else {
      return node
    }
    return super.visit(node.withExpression(extractExpr(tup)))
  }

  public override func visit(_ node: RepeatWhileStmtSyntax) -> StmtSyntax {
    guard let tup = node.condition as? TupleExprSyntax,
      tup.elementList.count == 1 else {
      return node
    }
    return node.withCondition(extractExpr(tup))
               .withWhileKeyword(node.whileKeyword.withOneTrailingSpace())
  }
}
