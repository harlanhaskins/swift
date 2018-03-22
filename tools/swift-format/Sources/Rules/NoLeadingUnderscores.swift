import Core
import Foundation
import SwiftSyntax

/// Identifiers should not have leading underscores.
///
/// This is intended to avoid certain antipatterns; `self.member = member` should be preferred to
/// `member = _member` and the leading underscore should not be used to signal access level.
///
/// Lint: Declaring an identifier with a leading underscore yields a lint error.
///
/// - SeeAlso: https://google.github.io/swift#naming-conventions-are-not-access-control
public final class NoLeadingUnderscores: SyntaxLintRule {

}
