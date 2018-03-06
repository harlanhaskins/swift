import XCTest
import SwiftFormat
import SwiftSyntax

final class ColonSpacingTests: XCTestCase {
  func testInvalidColonSpacing() {
    let original =
      """
      let v1: Int = 0
      let v2 : Int = 1
      let v3 :Int = 1
      let v4    :      Int = 1
      """
    let expected =
      """
      let v1: Int = 0
      let v2: Int = 1
      let v3: Int = 1
      let v4: Int = 1
      """
    do {
      let syntax =
        try SourceFileSyntax.parse(original)
      let result = ColonSpaceFixingRewriter().visit(syntax)

      XCTAssertEqual(result.description, expected)
    } catch {
      XCTFail("\(error)")
    }
  }

  #if !os(macOS)
  static let allTests = [
    ColonSpacingTests.testInvalidColonSpacing
  ]
  #endif
}
