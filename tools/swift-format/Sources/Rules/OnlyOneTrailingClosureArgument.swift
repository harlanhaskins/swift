import Core
import Foundation
import SwiftSyntax

/// Function calls should never mix normal closure arguments and trailing closures.
///
/// Lint: If a function call with a trailing closure also contains a non-trailing closure argument,
///       a lint error is raised.
///
/// - SeeAlso: https://google.github.io/swift#trailing-closures
public final class OnlyOneTrailingClosureArgument: SyntaxLintRule {

}
