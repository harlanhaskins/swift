import Core
import Foundation
import SwiftSyntax

/// Force-unwraps are strongly discouraged and must be documented.
///
/// Lint: If a force unwrap is used, a lint warning is raised.
///       TODO(abl): consider having documentation (e.g. a comment) cancel the warning?
///
/// - SeeAlso: https://google.github.io/swift#force-unwrapping-and-force-casts
public final class NeverForceUnwrap: SyntaxLintRule {

}
