import Core
import Foundation
import SwiftSyntax

/// `for` loops that consist of a single `if` statement must use `where` clauses instead.
///
/// Lint: `for` loops that consist of a single `if` statement yield a lint error.
///
/// Format: `for` loops that consist of a single `if` statement have the conditional of that
///         statement factored out to a `where` clause.
///
/// - SeeAlso: https://google.github.io/swift#for-where-loops
public final class UseWhereClausesInForLoops: SyntaxFormatRule {

}
