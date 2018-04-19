import Core
import Foundation
import SwiftSyntax

/// Enforces whitespace for opening braces.
///
/// Unless required by line wrapping, open braces appear on the same line as the declaration they
/// begin, with one space before them.
///
/// Lint: If a line break appears before an open brace, unless required by line wrapping, a lint
///       error is raised.
///       If a line break does not appear after an open brace, except when allowed by One Statement
///       Per Line or before a closure signature, a lint error is raised.
///
/// Format: Unless required by line wrapping, line breaks before opening braces will be removed, and
///         appropriate spacing will be inserted.
///
/// - SeeAlso: https://google.github.io/swift#braces
public final class OpenBraceWhitespace: SyntaxFormatRule {

}
