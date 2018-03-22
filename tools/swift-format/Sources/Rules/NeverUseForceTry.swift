import Core
import Foundation
import SwiftSyntax

/// Force-try (`try!`) is forbidden.
///
/// This rule does not apply to test code, defined as code which matches one or more of:
///   * Parent directory named "Tests"
///   * Contains the line `import XCTest`
///
/// Lint: Using `try!` results in a lint error.
///
/// Format: The use of `try!` is replaced with a `try`...`catch` block where the `catch` block
///         contains `fatalError("TODO(<username>): document before submitting")`
///
/// - SeeAlso: https://google.github.io/swift#error-types
public final class NeverUseForceTry: SyntaxFormatRule {

}
