import Core
import Foundation
import SwiftSyntax

/// Use caseless `enum`s for namespacing.
///
/// In practice, this means that any `class` or `struct` that consists of only `static let`s and
/// `static func`s should be converted to an `enum`.
///
/// Lint: `class`es or `struct`s consisting of only `static let/funs=c`s will yield a lint error.
///
/// Format: Rewrite the `class` or `struct` as an `enum`.
///         TODO(abl): This can get complicated to pattern-match correctly.
///
/// - SeeAlso: https://google.github.io/swift#nesting-and-namespacing
public final class UseEnumForNamespacing: SyntaxFormatRule {

}
