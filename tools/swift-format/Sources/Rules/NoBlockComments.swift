import Core
import Foundation
import SwiftSyntax

/// Block comments should be avoided in favor of line comments.
///
/// Lint: If a block comment appears, a lint error is raised.
///
/// Format: If a block comment appears on its own on a line, or if a block comment spans multiple
///         lines without appearing on the same line as code, it will be replaced with multiple
///         single-line comments.
///         If a block comment appears inline with code, it will be removed and hoisted to the line
///         above the code it appears on.
///
/// - SeeAlso: https://google.github.io/swift#non-documentation-comments
public final class NoBlockComments: SyntaxFormatRule {

}
