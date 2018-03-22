import SwiftSyntax

public protocol LintRule: Rule {
  var diagnosticEngine: DiagnosticEngine { get }
}

open class SyntaxLintRule: SyntaxVisitor, LintRule {
  public var diagnosticEngine: DiagnosticEngine

  public init(diagnosticEngine: DiagnosticEngine) {
    self.diagnosticEngine = diagnosticEngine
  }
}
