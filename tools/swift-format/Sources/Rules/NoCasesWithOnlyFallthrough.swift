import Core
import Foundation
import SwiftSyntax

/// Cases that contain only the `fallthrough` statement are forbidden.
///
/// Lint: Cases containing only the `fallthrough` statement yield a lint error.
///
/// Format: The fallthrough `case` is added as a prefix to the next case unless the next case is
///         `default`; in that case, the fallthrough `case` is deleted.
///
/// - SeeAlso: https://google.github.io/swift#fallthrough-in-switch-statements
public final class NoCasesWithOnlyFallthrough: SyntaxFormatRule {

}
