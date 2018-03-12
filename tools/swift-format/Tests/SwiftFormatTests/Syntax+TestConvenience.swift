import Foundation
import SwiftSyntax
import XCTest

let tmpDir = URL(fileURLWithPath: NSTemporaryDirectory())

func XCTAssertFormatting(_ formatter: SyntaxRewriter,
                         input: String, expected: String,
                         file: StaticString = #file, line: UInt = #line) {
  do {
    let syntax =
      try SourceFileSyntax.parse(input)
    let result = formatter.visit(syntax)

    XCTAssertEqual(result.description, expected,
                   file: file, line: line)
  } catch {
    XCTFail("\(error)", file: file, line: line)
  }
}

extension SourceFileSyntax {
  /// Copies the text into a temporary file, parses that, and then deletes the
  /// temporary file.
  static func parse(_ text: String) throws -> SourceFileSyntax {
    let tmpFile =
      tmpDir
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("swift")
    let fm = FileManager.default
    if fm.fileExists(atPath: tmpFile.path) {
      try fm.removeItem(atPath: tmpFile.path)
    }
    fm.createFile(atPath: tmpFile.path, contents: text.data(using: .utf8)!)
    let source = try self.parse(tmpFile)
    try fm.removeItem(atPath: tmpFile.path)
    return source
  }
}
