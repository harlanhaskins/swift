import Core
import Foundation
import SwiftSyntax

/// Each `case` of a `switch` statement must be indented the same as the `switch` keyword.
///
/// Lint: If a case's indentation is over- or under-indented relative to the `switch` keyword, a
///       lint error is raised.
///
/// Format: Cases will be re-indented to match their accompanying `switch` keyword.
///
/// - SeeAlso: https://google.github.io/swift#switch-statements
public final class CaseIndentLevelEqualsSwitch: SyntaxFormatRule {

}
