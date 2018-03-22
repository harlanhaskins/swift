import SwiftSyntax

public protocol FormatRule: LintRule {

}

open class SyntaxFormatRule: SyntaxRewriter, FormatRule {
  public var diagnosticEngine: DiagnosticEngine

  public init(diagnosticEngine: DiagnosticEngine) {
    self.diagnosticEngine = diagnosticEngine
  }
}
