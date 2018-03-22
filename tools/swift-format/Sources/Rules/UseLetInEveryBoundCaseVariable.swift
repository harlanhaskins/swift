import Core
import Foundation
import SwiftSyntax

/// Every element bound in a `case` must have its own `let`.
///
/// e.g. `case let .label(foo, bar)` is forbidden.
///
/// Lint: `case let ...` will yield a lint error.
///
/// Format: The `let` will be distributed across each element.
///         TODO(abl): This is not a neutral format operation.
///
/// - SeeAlso: https://google.github.io/swift#pattern-matching
public final class UseLetInEveryBoundCaseVariable: SyntaxFormatRule {

}
