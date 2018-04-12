import SwiftSyntax
import XCTest

@testable import Rules

public class ColonWhitespaceTests: DiagnosingTestCase {
  public func testInvalidColonWhitespace() {
    XCTAssertFormatting(
      ColonWhitespace.self,
      input: """
             let v1: Int = 0
             let v2 : Int = 1
             let v3 :Int = 1
             let v4    \t: \t     Int = 1
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
    ColonWhitespaceTests.testInvalidColonWhitespace,
  ]
  #endif
}
