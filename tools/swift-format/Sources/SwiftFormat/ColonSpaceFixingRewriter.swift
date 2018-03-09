import Foundation
import SwiftSyntax

/// Ensures all colons in a file have exactly 0 spaces before, and exactly
/// 1 space after.
public final class ColonSpaceFixingRewriter: SyntaxRewriter {
  public override func visit(_ token: TokenSyntax) -> Syntax {
    guard let next = token.nextToken else { return token }

    /// Colons own their trailing spaces, so ensure it only has 1 if there's
    /// another token on the same line.
    if token.tokenKind == .colon, !next.leadingTrivia.containsNewlines {
      return token.withTrailingTrivia(
        token.trailingTrivia.withOneTrailingSpace())
    }

    /// Otherwise, colon-adjacent tokens should have 0 spaces after.
    if next.tokenKind == .colon {
      return token.withTrailingTrivia(token.trailingTrivia.withoutSpaces())
    }
    return token
  }
}
