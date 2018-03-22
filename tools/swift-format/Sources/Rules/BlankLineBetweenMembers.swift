import Core
import Foundation
import SwiftSyntax

/// At least one blank line between each member of a type.
///
/// Optionally, declarations of single-line properties can be ignored.
///
/// Lint: If more than the maximum number of blank lines appear, a lint error is raised.
///       If there are no blank lines between members, a lint error is raised.
///
/// Format: Declarations with no blank lines will have a blank line inserted.
///         Declarations with more than the maximum number of blank lines will be reduced to the
//          maximum number of blank lines.
///
/// Configuration: maximumBlankLines, blankLineBetweenMembers.ignoreSingleLineProperties
///
/// - SeeAlso: https://google.github.io/swift#vertical-whitespace
public final class BlankLineBetweenMembers: SyntaxFormatRule {

}
