import Foundation
import XCTest
import SwiftSyntax

@testable import Rules

public class NoVoidReturnOnFunctionSignatureTests: DiagnosingTestCase {
  public func testVoidReturns() {
    XCTAssertFormatting(
      NoVoidReturnOnFunctionSignature.self,
      input: """
             func foo() -> () {
             }

             func test() -> Void{
             }

             func x() -> Int { return 2 }

             let x = { () -> Void in
               print("Hello, world!")
             }
             """,
      expected: """
                func foo() {
                }

                func test() {
                }

                func x() -> Int { return 2 }

                let x = { () -> Void in
                  print("Hello, world!")
                }
                """)
  }

#if !os(macOS)
  static let allTests = [
    NoVoidReturnOnFunctionSignatureTests.testVoidReturns,
  ]
#endif

}
