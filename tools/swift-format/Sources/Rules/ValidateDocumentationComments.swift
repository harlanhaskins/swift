import Core
import Foundation
import SwiftSyntax

/// Documentation comments must be complete and valid.
///
/// "Command + Option + /" in Xcode produces a minimal valid documentation comment.
///
/// Lint: Documentation comments that are incomplete (e.g. missing parameter documentation) or
///       invalid (uses `Parameters` when there is only one parameter) will yield a lint error.
///
/// - SeeAlso: https://google.github.io/swift#parameter-returns-and-throws-tags
public final class ValidateDocumentationComments: SyntaxLintRule {

}
