import XCTest

@testable import SwiftFormatTests

#if !os(macOS)
XCTMain([
  ColonSpacingTests.allTests,
  ForLoopWhereTests.allTests,
  SplitVariableDeclarationsTests.allTests,
  BraceSpacingTests.allTests,
  VoidReturnTypeTests.allTests
  BalancedTokenSpacingTests.allTests
])
#endif
