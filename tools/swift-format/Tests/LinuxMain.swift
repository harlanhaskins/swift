#if os(Linux)
import SwiftFormatTests
import XCTest

XCTMain([
  ColonWhitespaceTests.allTests,
  DoNotUseSemicolonsTests.allTests,
  MultilineTrailingCommasTests.allTests,
].joined())
#endif
