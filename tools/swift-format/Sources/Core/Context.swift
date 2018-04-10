import Configuration
import Foundation
import SwiftSyntax

/// Context contains the bits that each formatter and linter will need access to.
///
/// Specifically, it is the container for the shared configuration, diagnostic engine, and URL of
/// the current file.
public class Context {
  public let configuration: Configuration
  public let diagnosticEngine: DiagnosticEngine
  public let fileURL: URL

  public init(configuration: Configuration, diagnosticEngine: DiagnosticEngine, fileURL: URL) {
    self.configuration = configuration
    self.diagnosticEngine = diagnosticEngine
    self.fileURL = fileURL
  }
}
