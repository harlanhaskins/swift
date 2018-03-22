import Core
import Foundation
import SwiftSyntax

/// Enforce whitespace for close braces.
///
/// Lint: If a close brace does not have a line break before it, except as covered by One Statement
///       Per Line, a lint error will be raised.
///
/// Format: Line breaks will be inserted for all non-conforming close braces.
///
/// - SeeAlso: https://google.github.io/swift#braces
public final class OneStatementPerLine: SyntaxFormatRule {

}
