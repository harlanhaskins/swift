import SwiftSyntax

/// A rule that both formats and lints a given file.
open class SyntaxFormatRule: SyntaxRewriter, Rule {
  /// The context in which the rule is executed.
  public let context: Context

  /// Creates a new SyntaxFormatRule in the given context.
  public required init(context: Context) {
    self.context = context
  }
}
