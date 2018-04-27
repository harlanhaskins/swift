import Foundation
import XCTest
import SwiftSyntax

@testable import Rules

public class UseSingleLinePropertyGetterTests: DiagnosingTestCase {
  public func testMultiLinePropertyGetter() {
    XCTAssertFormatting(
      UseSingleLinePropertyGetter.self,
      input: """
             var g: Int { return 4 }
             var h: Int {
               get {
                 return 4
               }
             }
             var i: Int {
               get { return 0 }
               set { print("no set, only get") }
             }
             """,
      expected: """
                var g: Int { return 4 }
                var h: Int {
                    return 4
                }
                var i: Int {
                  get { return 0 }
                  set { print("no set, only get") }
                }
                """)
  }

  #if !os(macOS)
  static let allTests = [
    UseSingleLinePropertyGetterTests.testMultiLinePropertyGetter,
  ]
  #endif
}
