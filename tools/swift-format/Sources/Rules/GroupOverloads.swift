import Core
import Foundation
import SwiftSyntax

/// Overloads, subscripts, and initializers should be grouped together if they appear in the same
/// scope.
/// Lint: If an overload appears ungrouped with another member of the overload set, a lint error
///       will be raised.
/// Format: Overloaded declarations will be grouped together.
/// - SeeAlso: https://google.github.io/swift#overloaded-declarations
public final class GroupOverloads: SyntaxFormatRule {

}
