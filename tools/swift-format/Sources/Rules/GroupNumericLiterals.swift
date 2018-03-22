import Core
import Foundation
import SwiftSyntax

/// Numeric literals should be grouped with `_`s to delimit common separators.
/// Specifically, decimal numeric literals should be grouped every 3 numbers, hexadecimal every 4,
/// and binary every 8.
///
/// Lint: If a numeric literal is too long and should be grouped, a lint error is raised.
///
/// Format: All numeric literals that should be grouped will have `_`s inserted where appropriate.
///
/// - SeeAlso: https://google.github.io/swift#numeric-literals
public final class GroupNumericLiterals: SyntaxFormatRule {

}
