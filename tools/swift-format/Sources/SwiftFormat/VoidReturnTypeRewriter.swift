import Foundation
import SwiftSyntax

public final class VoidReturnTypeRewriter: SyntaxRewriter {
  /// Remove the `-> Void` return type for function signatures. Do not remove
  /// it for closure signatures, because that may introduce an ambiguity.
  public override func visit(_ node: FunctionSignatureSyntax) -> Syntax {
    guard let tup = node.output?.returnType as? TupleTypeSyntax,
          tup.elements.isEmpty else {
      return node
    }
    return node.withOutput(nil)
  }

  /// In function types, replace a returned `()` with `Void`.
  public override func visit(_ node: FunctionTypeSyntax) -> TypeSyntax {
    guard let tup = node.returnType as? TupleTypeSyntax else { return node }
    guard tup.elements.isEmpty else { return node }
    let id = SyntaxFactory.makeTypeIdentifier("Void",
      leadingTrivia: tup.leftParen.leadingTrivia,
      trailingTrivia: tup.rightParen.trailingTrivia
    )
    return node.withReturnType(id)
  }

  /// In closure signatures, replace a returned `()` with `Void`.
  public override func visit(_ node: ClosureSignatureSyntax) -> Syntax {
    guard let tup = node.output?.returnType as? TupleTypeSyntax else {
      return node
    }
    guard tup.elements.isEmpty else { return node }
    let id = SyntaxFactory.makeTypeIdentifier("Void",
      leadingTrivia: tup.leftParen.leadingTrivia,
      trailingTrivia: tup.rightParen.trailingTrivia
    )
    return node.withOutput(node.output?.withReturnType(id))
  }
}
