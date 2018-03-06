import Foundation
import SwiftSyntax

public final class VoidReturnTypeRewriter: SyntaxRewriter {
  public override func visit(_ node: ReturnClauseSyntax) -> Syntax {
    guard let tup = node.returnType as? TupleTypeSyntax else { return node }
    guard tup.elements.isEmpty else { return node }
    let id = SyntaxFactory.makeTypeIdentifier("Void",
      leadingTrivia: tup.leftParen.leadingTrivia,
      trailingTrivia: tup.rightParen.trailingTrivia
    )
    return node.withReturnType(id)
  }
  public override func visit(_ node: FunctionTypeSyntax) -> TypeSyntax {
    guard let tup = node.returnType as? TupleTypeSyntax else { return node }
    guard tup.elements.isEmpty else { return node }
    let id = SyntaxFactory.makeTypeIdentifier("Void",
      leadingTrivia: tup.leftParen.leadingTrivia,
      trailingTrivia: tup.rightParen.trailingTrivia
    )
    return node.withReturnType(id)
  }
}
