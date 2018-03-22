import Core
import Foundation
import SwiftSyntax

/// Function calls with no arguments and a trailing closure should not have empty parentheses.
///
/// Lint: If a function call with a trailing closure has an empty argument list with parentheses,
///       a lint error is raised.
///
/// Format: Empty parentheses in function calls with trailing closures will be removed.
///
/// - SeeAlso: https://google.github.io/swift#trailing-closures
public final class NoEmptyTrailingClosureParentheses: SyntaxLintRule {

}
