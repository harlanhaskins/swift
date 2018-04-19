import Core
import Foundation
import SwiftSyntax

/// Enforces line length limits.
///
/// Lint: If a line exceeds the maximum line length, a lint error is raised.
///
/// Format: Overloaded declarations will be grouped together.
///
/// - SeeAlso: https://google.github.io/swift#column-limit
public final class LineLengthLimit: SyntaxLintRule {

}
