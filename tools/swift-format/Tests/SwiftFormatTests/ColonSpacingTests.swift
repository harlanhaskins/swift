import XCTest
import SwiftFormat
import SwiftSyntax

final class ColonSpacingTests: XCTestCase {
  func testInvalidColonSpacing() {
    XCTAssertFormatting(ColonSpaceFixingRewriter(),
      input: """
             let v1: Int = 0
             let v2 : Int = 1
             let v3 :Int = 1
             let v4    :      Int = 1
             """,
      expected: """
                let v1: Int = 0
                let v2: Int = 1
                let v3: Int = 1
                let v4: Int = 1
                """)
  }

  #if !os(macOS)
  static let allTests = [
    ColonSpacingTests.testInvalidColonSpacing
  ]
  #endif
}
