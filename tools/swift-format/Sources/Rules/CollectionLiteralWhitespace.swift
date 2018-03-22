import Core
import Foundation
import SwiftSyntax

/// Enforces whitespace requirements for array literals, tuples, and dictionary literals.
///
/// Lint: If an array, dictionary, or tuple literal it on a single line, and there are any spaces
///       after the opening delimiter, or any spaces before the closing delimiter, a lint
///       error is raised.
///
/// Format: Extraneous spaces at the beginning and end of collection literals will be removed.
///
/// - SeeAlso: https://google.github.io/swift#horizontal-whitespace
public final class CollectionLiteralWhitespace: SyntaxFormatRule {

}
