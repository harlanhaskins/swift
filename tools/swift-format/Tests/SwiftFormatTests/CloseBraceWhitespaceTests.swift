import Foundation
import XCTest
import SwiftSyntax

@testable import Rules

public class CloseBraceWhitespaceTests: DiagnosingTestCase {
  public func testInvalidCloseBraceWhitespace() {
    XCTAssertFormatting(
      CloseBraceWhitespace.self,
      input: """
             func a()
             { print("hello")
               print("goodbye")}
             func b(){
             }
             func c() {}
             """,
      expected: """
                func a()
                { print("hello")
                  print("goodbye")
                }
                func b(){
                }
                func c() {}
                """)
  }

#if !os(macOS)
  static let allTests = [
    CloseBraceWhitespaceTests.testInvalidCloseBraceWhitespace,
  ]
#endif

}

