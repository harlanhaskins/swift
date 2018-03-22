import Core
import Foundation
import SwiftSyntax

/// Each variable declaration, with the exception of tuple destructuring, should declare 1 variable.
///
/// Lint: If a variable declaration declares multiple variables, a lint error is raised.
///
/// Format: If a variable declaration declares multiple variables, it will be split into multiple
///         declarations, each declaring one of the variables.
///
/// - SeeAlso: https://google.github.io/swift#properties
public final class OneVariableDeclarationPerLine: SyntaxFormatRule {

}
