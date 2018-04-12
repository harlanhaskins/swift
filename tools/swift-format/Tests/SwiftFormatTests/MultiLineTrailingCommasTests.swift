import Foundation
import XCTest
import SwiftSyntax

@testable import Rules

public class MultiLineTrailingCommasTests: DiagnosingTestCase {
  public func testMissedTrailingCommas() {
    XCTAssertFormatting(
      MultiLineTrailingCommas.self,
      input: """
             let brothersStrong = [
               "Strong Bad",
               "Strong Sad",
               "Strong Mad"
             ]

             let programs = [
               "email": ["sbemail.exe", "hremail.exe"],
               "antivirus": ["edgardware.exe", "edgajr.exe"]
             ]
             """,
      expected: """
                let brothersStrong = [
                  "Strong Bad",
                  "Strong Sad",
                  "Strong Mad",
                ]

                let programs = [
                  "email": ["sbemail.exe", "hremail.exe"],
                  "antivirus": ["edgardware.exe", "edgajr.exe"],
                ]
                """)
  }

#if !os(macOS)
  static let allTests = [
    MultiLineTrailingCommasTests.testMissedTrailingCommas,
  ]
#endif

}
