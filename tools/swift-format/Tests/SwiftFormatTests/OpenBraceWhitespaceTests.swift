import Foundation
import XCTest
import SwiftSyntax

@testable import Rules

public class OpenBraceWhitespaceTests: DiagnosingTestCase {
  public func testInvalidOpenBraceWhitespace() {
    XCTAssertFormatting(
      OpenBraceWhitespace.self,
      input: """
             func a()
             {}
             func b(){
             }
             func c() {}
             func d()        {}
             """,
      expected: """
                func a() {}
                func b() {
                }
                func c() {}
                func d() {}
                """)
  }

#if !os(macOS)
  static let allTests = [
    OpenBraceWhitespaceTests.testInvalidOpenBraceWhitespace,
  ]
#endif

}
