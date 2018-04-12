import Foundation
import XCTest
import SwiftSyntax

@testable import Rules

public class DoNotUseSemicolonsTests: DiagnosingTestCase {
  public func testSemicolonUse() {
    XCTAssertFormatting(
      DoNotUseSemicolons.self,
      input: """
             print("hello"); print("goodbye");
             print("3")
             """,
      expected: """
                print("hello")
                print("goodbye")
                print("3")
                """)
  }

#if !os(macOS)
  static let allTests = [
    DoNotUseSemicolonsTests.testSemicolonUse,
  ]
#endif

}
