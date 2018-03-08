import XCTest
import SwiftFormat
import SwiftSyntax

final class BraceSpacingTests: XCTestCase {
  func testInvalidBraceSpacing() {
    XCTAssertFormatting(BraceSpaceFixingRewriter(),
      input: """
             func a()
             {}
             func b(){
             }
             func c() {}
             func d()        {}
             """,
      expected: """
                func a() {
                }
                func b() {
                }
                func c() {
                }
                func d() {
                }
                """)
  }

  #if !os(macOS)
  static let allTests = [
    BraceSpacingTests.testInvalidBraceSpacing
  ]
  #endif
}
