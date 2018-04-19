#if os(Linux)
import SwiftFormatTests
import XCTest

XCTMain([
  ColonWhitespaceTests.allTests,
  DoNotUseSemicolonsTests.allTests,
  MultiLineTrailingCommasTests.allTests,
  NoParensAroundConditionsTests.allTests,
  UseEnumForNamespacingTests.allTests,
  AvoidInitializersForLiteralsTests.allTests,
  CollectionLiteralWhitespaceTests.allTests,
  NoVoidReturnOnFunctionSignatureTests.allTests,
].joined())
#endif
