import Foundation
import SwiftSyntax
import XCTest

@testable import Rules

public class UseEnumForNamespacingTests: DiagnosingTestCase {
  public func testNonEnumsUsedAsNamespaces() {
    XCTAssertFormatting(
      UseEnumForNamespacing.self,
      input: """
             struct A {
               static func foo() {}
               private init() {}
             }
             struct B {
               var x: Int = 3
               static func foo() {}
               private init() {}
             }
             class C {
               static func foo() {}
             }
             """,
      expected: """
                enum A {
                  static func foo() {}
                }
                struct B {
                  var x: Int = 3
                  static func foo() {}
                  private init() {}
                }
                enum C {
                  static func foo() {}
                }
                """)
  }

#if !os(macOS)
  static let allTests = [
    UseEnumForNamespacingTests.testNonEnumsUsedAsNamespaces,
  ]
#endif

}
