import Core
import Foundation
import SwiftSyntax

/// If all cases of an enum are `indirect`, the entire enum should be marked `indirect`.
///
/// Lint: If every case of an enum is `indirect`, but the enum itself is not, a lint error is
///       raised.
///
/// Format: Enums where all cases are `indirect` will be rewritten such that the enum is marked
///         `indirect`, and each case is not.
///
/// - SeeAlso: https://google.github.io/swift#enum-cases
public final class FullyIndirectEnum: SyntaxFormatRule {

}
