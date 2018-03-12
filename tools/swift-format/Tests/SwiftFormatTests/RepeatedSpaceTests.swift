import XCTest
import SwiftFormat
import SwiftSyntax

final class RepeatedSpaceTests: XCTestCase {
  func testRepeatedSpaces() {
    XCTAssertFormatting(RepeatedSpaceFixingRewriter(),
      input: """
             import    Foundation
             public  func foo(    /* foo */     x  : Int) ->     Int {
               return                                3
             }
             """,
      expected: """
                import Foundation
                public func foo( /* foo */ x : Int) -> Int {
                  return 3
                }
                """)
  }

  #if !os(macOS)
  static let allTests = [
    RepeatedSpaceTests.testRepeatedSpaces
  ]
  #endif
}
