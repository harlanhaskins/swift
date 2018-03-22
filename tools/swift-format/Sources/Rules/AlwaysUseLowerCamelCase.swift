import Core
import Foundation
import SwiftSyntax

/// All values should be written in lower camel-case (`lowerCamelCase`).
/// Underscores (except at the beginning of an identifier) are disallowed.
///
/// Lint: If an identifier contains underscores or begins with a capital letter, a lint error is
///       raised.
///
/// - SeeAlso: https://google.github.io/swift#identifiers
public final class AlwaysUseLowerCamelCase: SyntaxLintRule {

}
