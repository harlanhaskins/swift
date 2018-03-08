import XCTest
import SwiftFormat
import SwiftSyntax

final class SplitVariableDeclarationsTests: XCTestCase {
  func testMultipleBindings() {
    XCTAssertFormatting(SplitVariableDeclarationsRewriter(),
      input: """
             var a = 0, b = 2, (c, d) = (0, "h")
             let e = 0, f = 2, (g, h) = (0, "h")
             """,
      expected: """
                var a = 0
                var b = 2
                var (c, d) = (0, "h")
                let e = 0
                let f = 2
                let (g, h) = (0, "h")
                """)
  }

  #if !os(macOS)
  static let allTests = [
    SplitVariableDeclarationsTests.testMultipleBindings
  ]
  #endif
}
