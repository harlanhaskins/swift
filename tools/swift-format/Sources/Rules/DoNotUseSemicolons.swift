import Core
import Foundation
import SwiftSyntax

/// Semicolons should not be present in Swift code.
///
/// Lint: If a semicolon appears anywhere, a lint error is raised.
///
/// Format: All semicolons will be replaced with line breaks.
///
/// - SeeAlso: https://google.github.io/swift#semicolons
public final class DoNotUseSemicolons: SyntaxFormatRule {

}
