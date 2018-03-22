import Core
import Foundation
import SwiftSyntax

/// All documentation comments must begin with a one-line summary of the declaration.
///
/// Lint: If a comment does not begin with a single-line summary, a lint error is raised.
///
/// - SeeAlso: https://google.github.io/swift#single-sentence-summary
public final class BeginDocumentationCommentWithOneLineSummary: SyntaxLintRule {

}
