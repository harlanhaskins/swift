import Core
import Foundation
import SwiftSyntax

/// Implicitly unwrapped optionals (e.g. `var s: String!`) are forbidden.
///
/// Certain properties (e.g. `@IBOutlet`) tied to the UI lifecycle are ignored.
///
/// This rule does not apply to test code, defined as code which matches one or more of:
///   * Parent directory named "Tests"
///   * Contains the line `import XCTest`
///
/// Lint: Declaring a property with an implicitly unwrapped type yields a lint error.
///
/// - SeeAlso: https://google.github.io/swift#implicitly-unwrapped-optionals
public final class NeverUseImplicitlyUnwrappedOptionals: SyntaxLintRule {

}
