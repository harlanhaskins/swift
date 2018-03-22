import Core
import Foundation
import SwiftSyntax

/// When possible, the synthesized `struct` initializer should be used.
///
/// This means the creation of a (non-public) memberwise initializer with the same structure as the
/// synthesized initializer is forbidden.
///
/// Lint: (Non-public) memberwise initializers with the same structure as the synthesized
///       initializer will yield a lint error.
///
/// - SeeAlso: https://google.github.io/swift#initializers-2
public final class UseSynthesizedInitializer: SyntaxLintRule {

}
