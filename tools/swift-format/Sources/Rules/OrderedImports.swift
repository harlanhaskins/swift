import Core
import Foundation
import SwiftSyntax

/// Imports must be lexicographically ordered and logically grouped at the top of each source file.
/// Lint: If an import appears anywhere other than the beginning of the file it resides in,
///       not lexicographically ordered, or  not in the appropriate import group, a lint error is
///       raised.
/// Format: Imports will be reordered and grouped at the top of the file.
/// - SeeAlso: https://google.github.io/swift#import-statements
public final class OrderedImports: SyntaxFormatRule {

}
