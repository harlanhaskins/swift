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
    guard !node.body.statements.isEmpty else { return node }
    let stmt = node.body.statements.first!

    // Ignore for-loops with a `where` clause already.
    // FIXME: Create an `&&` expression with both conditions?
    guard node.whereClause == nil else { return node }

    // Match:
    //  - If the for loop has 1 statement, and it is an IfStmt, with a single
    //    condition.
    //  - If the for loop has 1 or more statement, and the first is a GuardStmt
    //    with a single condition whose body is just `continue`.
    switch stmt.item {
    case let ifStmt as IfStmtSyntax
      where ifStmt.conditions.count == 1 &&
            node.body.statements.count == 1:
      // Extract the condition of the IfStmt.
      let conditionElement = ifStmt.conditions.first!
      guard let condition = conditionElement.condition as? ExprSyntax else {
        return node
      }
      return super.visit(updateWithWhereCondition(
        node: node,
        condition: condition,
        statements: ifStmt.body.statements
      ))
    case let guardStmt as GuardStmtSyntax
      where guardStmt.conditions.count == 1 &&
            guardStmt.body.statements.count == 1 &&
            guardStmt.body.statements.first!.item is ContinueStmtSyntax:
      // Extract the condition of the GuardStmt.
      let conditionElement = guardStmt.conditions.first!
      guard let condition = conditionElement.condition as? ExprSyntax else {
        return node
      }
      return super.visit(updateWithWhereCondition(
        node: node,
        condition: condition,
        statements: node.body.statements.removingFirst()
      ))
    default:
      return node
    }

  }
}

private func updateWithWhereCondition(
  node: ForInStmtSyntax,
  condition: ExprSyntax,
  statements: CodeBlockItemListSyntax
) -> ForInStmtSyntax {
  // Construct a new `where` clause with the condition.
  let lastToken = node.sequenceExpr.lastToken
  var whereLeadingTrivia = Trivia()
  if lastToken?.trailingTrivia.containsSpaces == false {
    whereLeadingTrivia = .spaces(1)
  }
  let whereKeyword = SyntaxFactory.makeWhereKeyword(
    leadingTrivia: whereLeadingTrivia,
    trailingTrivia: .spaces(1)
  )
  let whereClause = SyntaxFactory.makeWhereClause(
    whereKeyword: whereKeyword,
    guardResult: condition
  )

  // Replace the where clause and extract the body from the IfStmt.
  let newBody = node.body.withStatements(statements)
  return node.withWhereClause(whereClause)
    .withBody(newBody)
}
