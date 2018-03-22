import Core
import Foundation
import SwiftSyntax

/// Return `Void`, not `()`, in signatures.
///
/// Note that this rule does *not* apply to function declaration signatures in order to avoid
/// conflicting with `NoVoidReturnOnFunctionSignature`.
///
/// Lint: Returning `()` in a signature yields a lint error.
///
/// Format: `-> ()` is replaced with `-> Void`
///
/// - SeeAlso: https://google.github.io/swift#types-with-shorthand-names
public final class ReturnVoidInsteadOfEmptyTuple: SyntaxFormatRule {

}
