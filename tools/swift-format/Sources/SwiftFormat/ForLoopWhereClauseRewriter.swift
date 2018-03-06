import Foundation
import SwiftSyntax

/// Rewrites for loops whose entire body is wrapped in an if statement.
/// It will extract the condition of the if statement into a `where` clause
/// attached to the function body.
///
/// Example:
/// ```
/// for i in [0, 1, 2, 3, 4] {
///   if i > 4 {
///     print(i)
///   }
/// }
/// ```
/// converts to
/// ```
/// for i in [0, 1, 2, 3, 4] where i > 4 {
///     print(i)
/// }
/// ```
public final class ForLoopWhereClauseRewriter: SyntaxRewriter {
  public override func visit(_ node: ForInStmtSyntax) -> StmtSyntax {
    // Extract IfStmt node if it's the only node in the function's body.
    guard node.body.statements.count == 1 else { return node }
    let stmt = node.body.statements.first!
    guard let ifStmt = stmt.item as? IfStmtSyntax else { return node }
    guard ifStmt.conditions.count == 1 else { return node }

    // Ignore for-loops with a `where` clause already.
    // FIXME: Create an `&&` expression with both conditions?
    guard node.whereClause == nil else { return node }

    // Extract the condition of the IfStmt.
    let conditionElement = ifStmt.conditions.first!
    guard let condition = conditionElement.condition as? ExprSyntax else {
      return node
    }

    // Construct a new `where` clause with the condition.
    let lastToken = node.sequenceExpr.lastToken
    let whereKeyword = SyntaxFactory.makeWhereKeyword(
      leadingTrivia: lastToken?.trailingTrivia.withOneSpace() ?? .spaces(1),
      trailingTrivia: .spaces(1)
    )
    let whereClause = SyntaxFactory.makeWhereClause(
      whereKeyword: whereKeyword,
      guardResult: condition
    )

    // Replace the where clause and extract the body from the IfStmt.
    let newBody = node.body.withStatements(ifStmt.body.statements)
    return node.withWhereClause(whereClause)
               .withBody(newBody)
  }
}
