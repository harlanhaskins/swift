import Core
import Foundation
import SwiftSyntax

/// Functions that return `()` or `Void` should omit the return signature.
///
/// Lint: Function declarations that explicitly return `()` or `Void` will yield a lint error.
///
/// Format: Function declarations with explicit returns of `()` or `Void` will have their return
///         signature stripped.
///
/// - SeeAlso: https://google.github.io/swift#types-with-shorthand-names
public final class NoVoidReturnOnFunctionSignature: SyntaxFormatRule {

}
