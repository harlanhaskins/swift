import Core
import Foundation
import SwiftSyntax

/// Enum cases should not have an empty set of parentheses if they have no associated values.
///
/// Lint: If an enum case has an empty set of parentheses, declaring no associated values, a lint
///       error is raised.
///
/// Format: Enum cases with empty parentheses will have their parentheses removed.
///
/// - SeeAlso: https://google.github.io/swift#enum-cases
public final class NoEmptyAssociatedValues: SyntaxFormatRule {

}
