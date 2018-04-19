import Core
import Foundation
import SwiftSyntax

/// A single space is required before every expression on the same line as an opening brace.
///
/// Lint: If an expression appears on the same line as an opening brace with invalid spaces between
///       them, a lint error is raised.
///
/// Format: A single space will be inserted between opening braces and same-line expressions.
///
/// - SeeAlso: https://google.github.io/swift#horizontal-whitespace
public final class OneSpaceBeforeExpressions: SyntaxFormatRule {

}
