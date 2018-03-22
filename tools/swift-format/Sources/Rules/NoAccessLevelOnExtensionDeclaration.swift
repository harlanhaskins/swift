import Core
import Foundation
import SwiftSyntax

/// Specifying an access level for an extension declaration is forbidden.
///
/// Lint: Specifying an access level for an extension declaration yields a lint error.
///
/// Format: The access level is removed from the extension declaration and is added to each
///         declaration in the extension; declarations with redundant access levels (e.g.
///         `internal`, as that is the default access level) have the explicit access level removed.
///
/// - SeeAlso: https://google.github.io/swift#access-levels
public final class NoAccessLevelOnExtensionDeclaration: SyntaxFormatRule {

}
