import Core
import Foundation
import SwiftSyntax

/// Swift source files do not contain a copyright statement.
///
/// Lint: If the first comment in a source file contains a copyright statement, a lint error will
///       be raised.
///
/// Format: Copyright statements in source files will be removed.
///
/// - SeeAlso: https://google.github.io/swift#copyright-statement
public final class NoCopyrightStatement: SyntaxFormatRule {

}
