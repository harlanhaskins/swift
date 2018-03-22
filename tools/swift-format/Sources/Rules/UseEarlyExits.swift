import Core
import Foundation
import SwiftSyntax

/// Early exits should be used whenever possible.
///
/// Practically, this means that `if ... else return/throw/break` constructs should be replaced by
/// `guard ... else { return/throw/break }` constructs in order to keep indentation levels low.
///
/// Lint: `if ... else return/throw/break` constructs will yield a lint error.
///
/// Format: `if ... else return/throw/break` constructs will be replaced with equivalent
///         `guard ... else { return/throw/break }` constructs.
///         TODO(abl): replace implicit guards as well?
///
/// - SeeAlso: https://google.github.io/swift#guards-for-early-exits
public final class UseEarlyExits: SyntaxFormatRule {

}
