import Core
import Foundation
import SwiftSyntax

/// Read-only computed properties must use implicit `get` blocks.
///
/// Lint: Read-only computed properties with explicit `get` blocks yield a lint error.
///
/// Format: Explicit `get` blocks are rendered implicit by removing the `get`.
///
/// - SeeAlso: https://google.github.io/swift#properties-2
public final class UseSingleLinePropertyGetter: SyntaxFormatRule {

}
