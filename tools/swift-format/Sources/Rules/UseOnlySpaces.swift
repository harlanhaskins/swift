import Core
import Foundation

/// The only whitespace characters allowed are horizontal spaces and line terminators.
///
/// Character literals in `String`s are represented by their corresponding escape sequence.
/// Tab characters are not used for indentation.
///
/// Lint: Each line containing an illegal character will result in a lint error.
///
/// Format: Tabs will be replaced with eight spaces; all other whitespace characters will be
///         replaced with a single space. Inside string literals, the corresponding Unicode escape
///         will be used instead.
///
/// Configuration: tabWidth
///
/// - SeeAlso: https://google.github.io/swift#whitespace-characters

public final class UseOnlySpaces: FileRule {

}
