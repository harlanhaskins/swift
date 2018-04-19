#if os(Linux)
import SwiftFormatTests
import XCTest

XCTMain([
  ColonWhitespaceTests.allTests,
  DoNotUseSemicolonsTests.allTests,
  MultiLineTrailingCommasTests.allTests,
  NoParensAroundConditionsTests.allTests,
  AvoidInitializersForLiteralsTests.allTests,
].joined())
#endif
