import Core
import Foundation
import SwiftSyntax

/// Exactly zero spaces must appear before each colon, and exactly one space after, if not at the
/// end of a line.
///
/// Lint: If an invalid number of spaces appear before or after a colon, a lint error is
///       raised.
/// Format: All colons will have no spaces before, and a single space after.
/// - SeeAlso: https://google.github.io/swift#horizontal-whitespace
public final class ColonWhitespace: SyntaxFormatRule {

}
