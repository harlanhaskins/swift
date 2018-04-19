import SwiftSyntax
import XCTest

@testable import Rules

public class AvoidInitializersForLiteralsTests: DiagnosingTestCase {
  public func testInitializersForLiterals() {
    XCTAssertFormatting(
      AvoidInitializersForLiterals.self,
      input: """
             let v1 = UInt32(76)
             let v2 = UInt8(257)
             performFunction(x: Int16(54))
             performFunction(x: Int32(54))
             performFunction(x: Int64(54))
             let c = Character("s")
             """,
      expected: """
                let v1 = 76 as UInt32
                let v2 = 257 as UInt8
                performFunction(x: 54 as Int16)
                performFunction(x: 54 as Int32)
                performFunction(x: 54 as Int64)
                let c = "s" as Character
                """)
  }

  #if !os(macOS)
  static let allTests = [
    AvoidInitializersForLiteralsTests.testInitializersForLiterals,
  ]
  #endif
}
