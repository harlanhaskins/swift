import Core
import Foundation
import SwiftSyntax

/// Documentation comments must use the `///` form.
///
/// Flag comments (e.g. `// TODO(username):`) are exempted from this rule.
///
/// This is similar to `NoBlockComments` but is meant to prevent multi-line comments that use `//`.
///
/// Lint: If a declaration has a multi-line comment preceding it and that comment is not in `///`
///       form, a lint error is raised.
///
/// Format: If a declaration has a multi-line comment preceding it and that comment is not in `///`
///         form, it is converted to the `///` form.
///
/// - SeeAlso: https://google.github.io/swift#general-format
public final class UseTripleSlashForDocumentationComments {

}
