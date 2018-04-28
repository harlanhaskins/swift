import Foundation
import XCTest
import SwiftSyntax

@testable import Rules

public class OpenBraceWhitespaceTests: DiagnosingTestCase {
  public func testInvalidOpenBraceWhitespace() {
    let input =
    XCTAssertFormatting(
      OpenBraceWhitespace.self,
      input: """
             func a()
             {}
             func b(){
             }
             func c() {}
             func d()        {}
             if 5 > 6 { return }
             """,
      expected: """
                func a() {}
                func b() {
                }
                func c() {}
                func d() {}
                if 5 > 6 { return }
                """)
    XCTAssertDiagnosed(.noLineBreakBeforeOpenBrace)
    XCTAssertDiagnosed(.notEnoughSpacesBeforeOpenBrace)
    XCTAssertDiagnosed(.tooManySpacesBeforeOpenBrace)
  }

#if !os(macOS)
  static let allTests = [
    OpenBraceWhitespaceTests.testInvalidOpenBraceWhitespace,
  ]
#endif

}
