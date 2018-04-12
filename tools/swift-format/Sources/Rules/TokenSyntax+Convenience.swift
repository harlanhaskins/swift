import SwiftSyntax

extension TokenSyntax {
  /// Returns this token with only one space at the end of its trailing trivia.
  func withOneTrailingSpace() -> TokenSyntax {
    return withTrailingTrivia(trailingTrivia.withOneTrailingSpace())
  }

  /// Returns this token with only one space at the beginning of its leading
  /// trivia.
  func withOneLeadingSpace() -> TokenSyntax {
    return withLeadingTrivia(leadingTrivia.withOneLeadingSpace())
  }

  /// Returns this token with only one newline at the end of its leading trivia.
  func withOneTrailingNewline() -> TokenSyntax {
    return withTrailingTrivia(trailingTrivia.withOneTrailingNewline())
  }

  /// Returns this token with only one newline at the beginning of its leading
  /// trivia.
  func withOneLeadingNewline() -> TokenSyntax {
    return withLeadingTrivia(leadingTrivia.withOneLeadingNewline())
  }
}
