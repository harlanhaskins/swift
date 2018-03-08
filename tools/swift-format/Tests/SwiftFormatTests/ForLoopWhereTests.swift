import XCTest
import SwiftFormat
import SwiftSyntax

final class ForLoopWhereTests: XCTestCase {
  func testSimpleForLoop() {
    XCTAssertFormatting(ForLoopWhereClauseRewriter(),
      input: """
             for i in [0, 1, 2, 3] {
               if i > 30 {
                 print(i)
               }
             }

             for i in [0, 1, 2, 3] {
               guard i > 30 else {
                 continue
               }
               print(i)
             }
             """,
      expected: """
                for i in [0, 1, 2, 3] where i > 30 {
                    print(i)
                }

                for i in [0, 1, 2, 3] where i > 30 {
                  print(i)
                }
                """)
  }

  #if !os(macOS)
  static let allTests = [
    ForLoopWhereTests.testSimpleForLoop
  ]
  #endif
}
