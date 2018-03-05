import Foundation
import SwiftSyntax

struct Options {
  let sourceFiles: [URL]
}

extension Diagnostic.Message {
  static func unknownFile(_ path: String) -> Diagnostic.Message {
    return .init(.error, "unknown file '\(path)'")
  }
  static let noFilesProvided = Diagnostic.Message(.error, "no files provided")
}

struct Driver {
  let engine: DiagnosticEngine
  func parseArguments() -> Options? {
    let urls = CommandLine.arguments.dropFirst().compactMap { path -> URL? in
      guard FileManager.default.fileExists(atPath: path) else {
        engine.diagnose(.unknownFile(path))
        return nil
      }
      return URL(fileURLWithPath: path)
    }
    if urls.isEmpty {
      engine.diagnose(.noFilesProvided)
      return nil
    }
    return Options(sourceFiles: urls)
  }
}
