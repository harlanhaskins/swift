import Core
import Foundation
import SwiftSyntax

/// At least two spaces before, and exactly one space after the `//` that begins a line comment.
///
/// Lint: If an invalid number of spaces appear before or after a comment, a lint error is
///       raised.
/// Format: All comments will have at least 2 spaces before, and a single space after, the `//`.
/// - SeeAlso: https://google.github.io/swift#horizontal-whitespace
public final class CommentWhitespace: SyntaxFormatRule {

}
