import Core
import Foundation
import SwiftSyntax

/// Array and dictionary literals should have a trailing comma if their values are split on multiple
/// lines.
///
/// Lint: If an array or dictionary literal is split on multiple lines, and the last element does
///       not have a trailing comma, a lint error is raised.
///
/// Format: The last element of a multi-line array or dictionary literal will have a trailing comma
///         inserted if it does not have one already.
///
/// - SeeAlso: https://google.github.io/swift#trailing-commas
public final class MultiLineTrailingCommas: SyntaxFormatRule {

}
