import Core
import Foundation
import SwiftSyntax

/// Avoid using initializer-style casts for literals.
///
/// Using `UInt8(256)` will not error for overflow, leading to a runtime crash. Convert these to
/// `256 as UInt8`, to move the error from runtime to compile time.
///
/// Lint: If an initializer-style cast is used on a built-in type known to be expressible by
///       that kind of literal type, a lint error is raised.
///
/// Format: Initializer-style casts between known built-in types will be converted to standard
///         casts.
///
/// - SeeAlso: https://google.github.io/swift#numeric-and-string-literals
public final class AvoidInitializersForLiterals: SyntaxFormatRule {

}
