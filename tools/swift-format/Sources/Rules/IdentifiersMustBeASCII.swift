import Core
import Foundation
import SwiftSyntax

/// All identifiers must be ASCII.
///
/// Lint: If an identifier contains non-ASCII characters, a lint error is raised.
///
/// - SeeAlso: https://google.github.io/swift#identifiers
public final class IdentifiersMustBeASCII: SyntaxLintRule {

}
