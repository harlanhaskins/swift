import Core
import Foundation
import SwiftSyntax

/// A single space is required after every keyword that precedes another token on the same line.
///
/// Lint: If a keyword appears before a token on the same line without a space between them, a lint
///       error is raised.
/// Format: A single space will be inserted between keywords and other same-line tokens.
/// - SeeAlso: https://google.github.io/swift#horizontal-whitespace
public final class OneSpaceAfterKeywords: SyntaxFormatRule {

}
