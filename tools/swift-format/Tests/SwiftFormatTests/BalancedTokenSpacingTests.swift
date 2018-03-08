import XCTest
import SwiftFormat
import SwiftSyntax

final class BalancedTokenSpacingTests: XCTestCase {
  func testInvalidBalancedTokenSpacing() {
    XCTAssertFormatting(BalancedTokenSpaceFixingRewriter(),
      input: """
             func a( x: Int ) {
               print( [ x ] )
               if ( x == 0 ) {
                 var arr = Array< Int >()
                 arr.append(x )
                 print( arr)
               }
             }
             """,
      expected: """
                func a(x: Int) {
                  print([x])
                  if (x == 0) {
                    var arr = Array<Int>()
                    arr.append(x)
                    print(arr)
                  }
                }
                """)
  }

  #if !os(macOS)
  static let allTests = [
    BalancedTokenSpacingTests.testInvalidBalancedTokenSpacing
  ]
  #endif
}
