import Core
import Foundation
import SwiftSyntax

/// Array and dictionary literals should have a trailing comma if their values are split on multiple
/// lines.
///
/// Lint: If an array or dictionary literal is split on multiple lines, and the last element does
///       not have a trailing comma, a lint error is raised.
///
/// Format: The last element of a multi-line array or dictionary literal will have a trailing comma
///         inserted if it does not have one already.
///
/// - SeeAlso: https://google.github.io/swift#trailing-commas
public final class MultiLineTrailingCommas: SyntaxFormatRule {
  public override func visit(_ node: ArrayExprSyntax) -> ExprSyntax {
    guard !node.elements.isEmpty else { return node }

    let lastElt = node.elements[node.elements.count - 1]
    guard lastElt.trailingComma == nil else { return node }
    guard node.rightSquare.leadingTrivia.containsNewlines else { return node }

    // TODO(b/77534297): location for diagnostic
    diagnose(.addTrailingCommaArray, location: nil)

    // Insert a trailing comma before the existing trailing trivia
    let newElt = lastElt.withTrailingComma(
      SyntaxFactory.makeCommaToken(trailingTrivia: lastElt.trailingTrivia ?? [])
    )
    let newEltTriviaReplaced = replaceTrivia(
      on: newElt,
      token: newElt.expression.lastToken,
      trailingTrivia: []
    ) as! ArrayElementSyntax

    let newElements = node.elements.replacing(
      childAt: lastElt.indexInParent,
      with: newEltTriviaReplaced
    )
    return node.withElements(newElements)
  }

  public override func visit(_ node: DictionaryExprSyntax) -> ExprSyntax {
    guard let elements = node.content as? DictionaryElementListSyntax else { return node }
    guard !elements.isEmpty else { return node }

    let lastElt = elements[elements.count - 1]
    guard lastElt.trailingComma == nil else { return node }
    guard node.rightSquare.leadingTrivia.containsNewlines else { return node }

    // TODO(b/77534297): location for diagnostic
    diagnose(.addTrailingCommaDictionary, location: nil)

    // Insert a trailing comma before the existing trailing trivia
    let newElt = lastElt.withTrailingComma(
      SyntaxFactory.makeCommaToken(trailingTrivia: lastElt.trailingTrivia ?? [])
    )
    let newEltTriviaReplaced = replaceTrivia(
      on: newElt,
      token: newElt.valueExpression.lastToken,
      trailingTrivia: []
    ) as! DictionaryElementSyntax

    let newElements = elements.replacing(
      childAt: lastElt.indexInParent,
      with: newEltTriviaReplaced
    )
    return node.withContent(newElements)
  }
}

extension Diagnostic.Message {
  static let addTrailingCommaArray =
    Diagnostic.Message(.warning, "add trailing comma on last array literal element")
  static let addTrailingCommaDictionary =
    Diagnostic.Message(.warning, "add trailing comma on last dictionary literal element")
}
