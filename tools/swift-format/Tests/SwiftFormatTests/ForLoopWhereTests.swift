import XCTest
import SwiftFormat
import SwiftSyntax

final class ForLoopWhereTests: XCTestCase {
  func testSimpleForLoop() {
    let original =
      """
      for i in [0, 1, 2, 3] {
        if i > 30 {
          print(i)
        }
      }
      """
    let expected =
      """
      for i in [0, 1, 2, 3] where i > 30 {
          print(i)
      }
      """
    do {
      let syntax =
        try SourceFileSyntax.parse(original)
      let result = ForLoopWhereClauseRewriter().visit(syntax)

      XCTAssertEqual(result.description, expected)
    } catch {
      XCTFail("\(error)")
    }
  }

  #if !os(macOS)
  static let allTests = [
    ForLoopWhereTests.testSimpleForLoop
  ]
  #endif
}
