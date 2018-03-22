import Core
import Foundation
import SwiftSyntax

/// Enforce a maximum number of consecutive blank lines.
///
/// Lines containing only whitespace characters are considered blank (e.g. "^\s*$"). Multi-line
/// string literals are ignored by this rule.
///
/// Lint: A lint error is raised if more than maximumBlankLines appear consecutively.
///
/// Format: If more than maximumBlankLines appear consecutively they are reduced to a count of
///         maximumBlankLines.
///
/// Configuration: maximumBlankLines
///
/// - SeeAlso: https://google.github.io/swift#vertical-whitespace
public final class MaximumBlankLines: SyntaxFormatRule {

}
