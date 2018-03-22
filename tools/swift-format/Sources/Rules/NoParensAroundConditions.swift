import Core
import Foundation
import SwiftSyntax

/// Parentheses are not used around any condition of an `if`, `guard`, or `while` statement, or
/// around the matched expression in a `switch` statement.
///
/// Lint: If a top-most expression in a `switch`, `if`, `guard`, or `while` statement is surrounded
///       by parentheses, and it does not include a function call with a trailing closure, a lint
///       error is raised.
///
/// Format: Parentheses around such expressions are removed, if they do not cause a parse ambiguity.
///         Specifically, parentheses are allowed if and only if the expression contains a function
///         call with a trailing closure.
///
/// - SeeAlso: https://google.github.io/swift#parentheses
public final class NoParensAroundConditions: SyntaxFormatRule {

}
