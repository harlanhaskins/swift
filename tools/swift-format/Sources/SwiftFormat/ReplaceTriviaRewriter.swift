import Foundation
import SwiftSyntax

/// Replaces the leading or trailing trivia of a given node to the provided
/// leading and trailing trivia.
final class ReplaceTriviaRewriter: SyntaxRewriter {
  let leadingTrivia: Trivia?
  let trailingTrivia: Trivia?
  let lastToken: TokenSyntax?

  init(lastToken: TokenSyntax?,
    leadingTrivia: Trivia? = nil,
    trailingTrivia: Trivia? = nil
  ) {
    self.lastToken = lastToken
    self.leadingTrivia = leadingTrivia
    self.trailingTrivia = trailingTrivia
  }

  override func visit(_ token: TokenSyntax) -> Syntax {
    guard token == lastToken else { return token }
    return token.withLeadingTrivia(leadingTrivia ?? token.leadingTrivia)
                .withTrailingTrivia(trailingTrivia ?? token.trailingTrivia)
  }
}
