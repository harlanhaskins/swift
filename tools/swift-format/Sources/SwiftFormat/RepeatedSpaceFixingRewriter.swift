import Foundation
import SwiftSyntax

extension Trivia {
  /// Removes repeated spaces between tokens (ignoring repeated spaces at the
  /// beginning of a line).
  func removingRepeatedSpaces() -> Trivia {
    if containsNewlines { return self }
    return Trivia(pieces: condensed().map {
      if case .spaces = $0 {
        return .spaces(1)
      }
      return $0
    })
  }
}

public final class RepeatedSpaceFixingRewriter: SyntaxRewriter {
  public override func visit(_ token: TokenSyntax) -> Syntax {
    return token.withLeadingTrivia(
      token.leadingTrivia.removingRepeatedSpaces()
    ).withTrailingTrivia(
      token.trailingTrivia.removingRepeatedSpaces()
    )
  }
}
