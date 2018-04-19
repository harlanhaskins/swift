import Core
import Foundation
import SwiftSyntax

/// Exactly one space must appear before and after each binary operator token.
///
/// Lint: If an invalid number of spaces appear before or after a binary operator, a lint error is
///       raised.
///
/// Format: All binary operators will have a single space before and after.
///
/// - SeeAlso: https://google.github.io/swift#horizontal-whitespace
public final class OperatorWhitespace: SyntaxFormatRule {

}
