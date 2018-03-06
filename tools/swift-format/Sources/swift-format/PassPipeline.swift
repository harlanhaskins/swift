import Foundation
import SwiftSyntax

/// A PassPipeline contains an array of SyntaxRewriter passes that will
/// transform a given Syntax tree many times in succession.
public final class PassPipeline {
  /// The list of passes to apply, in order.
  private var passes = [SyntaxRewriter]()

  /// Schedules the provided pass to run next in the pipeline.
  /// - parameter pass: The SyntaxRewriter that will rewrite the current
  ///                   in-progress node.
  func schedule(_ pass: SyntaxRewriter) {
    passes.append(pass)
  }

  /// Applies all passes in order, passing in the previous pass's result into
  /// the next pass.
  /// - parameter syntax: The initial Syntax node to be rewritten.
  /// - returns: The resulting Syntax node after all passes have been applied
  ///            to it.
  func rewrite(_ syntax: Syntax) -> Syntax {
    return passes.reduce(syntax) { return $1.visit($0) }
  }
}
