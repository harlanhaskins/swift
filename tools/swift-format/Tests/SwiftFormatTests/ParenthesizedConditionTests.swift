import XCTest
import SwiftFormat
import SwiftSyntax

final class ParenthesizedConditionTests: XCTestCase {
  func testParenthesizedConditions() {
    XCTAssertFormatting(ParenthesizedConditionRewriter(),
      input: """
             if (x) {}
             while (x) {}
             guard (x), (y), (x == 3) else {}
             if (foo { x }) {}
             switch (4) { default: break }
             """,
      expected: """
                if x {}
                while x {}
                guard x, y, x == 3 else {}
                if (foo { x }) {}
                switch 4 { default: break }
                """)
  }

  #if !os(macOS)
  static let allTests = [
    BraceSpacingTests.testInvalidBraceSpacing
  ]
  #endif
}
