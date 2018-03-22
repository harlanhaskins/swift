import Core
import Foundation
import SwiftSyntax

/// Parameterized attributes must be written on individual lines, ordered lexicographically.
///
/// Lint: Parameterized attributes not on an individual line will yield a lint error.
///       Parameterized attributes not in lexicographic order will yield a lint error.
///
/// Format: Parameterized attributes will be placed on individual lines in lexicographic order.
///
/// - SeeAlso: https://google.github.io/swift#attributes
public final class ParameterizedAttributesOnNewLines: SyntaxFormatRule {

}
