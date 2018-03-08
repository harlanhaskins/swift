import XCTest
import SwiftFormat
import SwiftSyntax

final class VoidReturnTypeTests: XCTestCase {
  func testEmptyTupleReturnType() {
    XCTAssertFormatting(VoidReturnTypeRewriter(),
      input: """
             let foo: () -> () = {}
             let bar: () -> Void = {}
             let baz = { () -> () in return }

             func foo() -> () {
             }

             func test() -> (){
             }
             """,
      expected: """
                let foo: () -> Void = {}
                let bar: () -> Void = {}
                let baz = { () -> Void in return }

                func foo() {
                }

                func test() {
                }
                """)
  }

  #if !os(macOS)
  static let allTests = [
    VoidReturnTypeTests.testEmptyTupleReturnType
  ]
  #endif
}
