import Core
import Foundation

/// Enforces rules about when to use unicode escape sequences in `String`s.
///
/// For any character that has a special escape sequence (\t, \n, \r, \", \', \\, and \0), that
/// sequence is used rather than the equivalent Unicode (e.g., \u{000a}) escape sequence.
///
/// See: https://google.github.io/swift#special-escape-sequences
///
/// Lint: If a Unicode escape sequence appears in a string literal for a character that has a
///       corresponding special escape sequence, a lint error will be raised.
///
/// Format: Unicode escape sequences for characters which have a special escape sequence will
///         be replaced with the special escape sequence.
public final class UseSpecialEscapeSequences: FileRule {

}
