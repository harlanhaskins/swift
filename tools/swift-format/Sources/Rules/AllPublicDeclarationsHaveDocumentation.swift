import Core
import Foundation
import SwiftSyntax

/// All public or open declarations must have a top-level documentation comment.
///
/// Lint: If a public declaration is missing a documentation comment, a lint error is raised.
///
/// - SeeAlso: https://google.github.io/swift#where-to-document
public final class AllPublicDeclarationsHaveDocumentation: SyntaxLintRule {

}
