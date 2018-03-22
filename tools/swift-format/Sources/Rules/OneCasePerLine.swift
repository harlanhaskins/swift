import Core
import Foundation
import SwiftSyntax

/// Each enum case with associated values should appear on its own line.
///
/// Lint: If a single `case` declaration declares multiple cases, and any of them have associated
///       values, a lint error is raised.
///
/// Format: All case declarations with associated values will be moved to a new line.
///
/// - SeeAlso: https://google.github.io/swift#enum-cases
public final class OneCasePerLine: SyntaxFormatRule {

}
