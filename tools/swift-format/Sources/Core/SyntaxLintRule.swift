import SwiftSyntax

open class SyntaxLintRule: SyntaxVisitor, Rule {
  public let context: Context

  public required init(context: Context) {
    self.context = context
  }
}

extension Rule {
  /// Emits the provided diagnostic to the diagnostic engine.
  ///
  /// - Parameters:
  ///   - message: The diagnostic message to emit.
  ///   - location: The source location which the diagnostic should be attached.
  ///   - actions: A set of actions to add notes, highlights, and fix-its to diagnostics.
  public func diagnose(
    _ message: Diagnostic.Message,
    location: SourceLocation?,
    actions: ((inout Diagnostic.Builder) -> Void)? = nil
  ) {
    context.diagnosticEngine.diagnose(
      message.withRule(self),
      location: location,
      actions: actions
    )
  }
}
