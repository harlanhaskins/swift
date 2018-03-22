import Core
import Foundation
import SwiftSyntax

/// Redundant labels are forbidden in case patterns.
///
/// In practice, *all* case pattern labels should be redundant.
///
/// Lint: Using a label in a case statement yields a lint error unless the label does not match the
///       binding identifier.
///
/// Format: Redundant labels in case patterns are removed.
///
/// - SeeAlso: https://google.github.io/swift#pattern-matching
public final class NoLablesInCasePatterns: SyntaxFormatRule {

}
