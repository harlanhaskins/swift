import Foundation
import XCTest
import SwiftSyntax

@testable import Rules

public class CollectionLiteralWhitespaceTests: DiagnosingTestCase {
  public func testInvalidCollectionLiteralWhitespace() {
    XCTAssertFormatting(
      CollectionLiteralWhitespace.self,
      input: """
             func a( x: Int ) {
               print( [ x ] )
               if ( x == 0 ) {
                 var arr = [ Int ]()
                 arr.append(x )
                 print( arr)
               }
             }
             """,
      expected: """
                func a(x: Int) {
                  print([x])
                  if (x == 0) {
                    var arr = [Int]()
                    arr.append(x)
                    print(arr)
                  }
                }
                """)
  }

#if !os(macOS)
  static let allTests = [
    CollectionLiteralWhitespaceTests.testInvalidCollectionLiteralWhitespace,
  ]
#endif

}
