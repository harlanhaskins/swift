import XCTest

@testable import SwiftFormatTests

#if !os(macOS)
XCTMain([
  ColonSpacingTests.allTests
  ForLoopWhereTests.allTests
])
#endif
