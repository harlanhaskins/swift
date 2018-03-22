import Core
import Foundation
import SwiftSyntax

/// Overloads with only a closure argument should not be disambiguated by parameter labels.
///
/// Lint: If two overloaded functions with one closure parameter appear in the same scope, a lint
///       error is raised.
///
/// - SeeAlso: https://google.github.io/swift#trailing-closures
public final class AmbiguousTrailingClosureOverload: SyntaxLintRule {

}
