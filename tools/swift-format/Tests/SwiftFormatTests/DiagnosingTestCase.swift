import Configuration
import Core
import SwiftSyntax
import XCTest

/// DiagnosingTestCase is an XCTestCase subclass meant to inject diagnostic-specific testing
/// routines into specific formatting test cases.
public class DiagnosingTestCase: XCTestCase {
  /// The context each test runs in.
  public private(set) var context: Context?

  /// A helper that will keep track of the number of times a specific diagnostic was emitted.
  private var consumer = DiagnosticTrackingConsumer()

  private class DiagnosticTrackingConsumer: DiagnosticConsumer {
    var registeredDiagnostics = [String: Int]()
    func handle(_ diagnostic: Diagnostic) {
      registeredDiagnostics[diagnostic.message.text, default: 0] += 1
    }
    func finalize() {}
  }

  /// Creates a new Context and DiagnosticTrackingConsumer for this test case.
  public override func setUp() {
    context = Context(
      configuration: Configuration(),
      diagnosticEngine: DiagnosticEngine(),
      fileURL: URL(fileURLWithPath: "/tmp/test.swift")
    )
    consumer = DiagnosticTrackingConsumer()
    context?.diagnosticEngine?.addConsumer(consumer)
  }

  public override func tearDown() {
    // This will emit a test failure if a diagnostic is thrown but we don't explicitly call
    // XCTAssertDiagnosed for it. I (hbh) am personally on the fence about whether to include
    // this test.
    #if false
    for (diag, count) in consumer.registeredDiagnostics where count > 0 {
      XCTFail("unexpected diagnostic '\(diag)' thrown \(count) time\(count == 1 ? "" : "s")")
    }
    #endif
  }

  /// Asserts that the result of applying a formatter to the provided input code yields the output.
  ///
  /// This method should be called by each test of each rule.
  ///
  /// - Parameters:
  ///   - input: The unformatted input code.
  ///   - expected: The expected result of formatting the input code.
  ///   - file: The file the test resides in (defaults to the current caller's file)
  ///   - line:  The line the test resides in (defaults to the current caller's line)
  func XCTAssertFormatting(
    _ formatType: SyntaxFormatRule.Type,
    input: String,
    expected: String,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    do {
      let syntax = try SourceFileSyntax.parse(input)
      let formatter = formatType.init(context: context!)
      let result = formatter.visit(syntax)

      XCTAssertEqual(result.description, expected,
                     file: file, line: line)
    } catch {
      XCTFail("\(error)", file: file, line: line)
    }
  }

  /// Asserts that a specific diagnostic message was called, optionally checking how many times.
  ///
  /// - Parameters:
  ///   - message: The diagnostic message to check for.
  ///   - times: The number of times the diagnostic is expected to have been called. Defaults to 1.
  ///   - file: The file the test resides in (defaults to the current caller's file)
  ///   - line:  The line the test resides in (defaults to the current caller's line)
  func XCTAssertDiagnosed(
    _ message: Diagnostic.Message,
    times: Int = 1,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    guard let diag = consumer.registeredDiagnostics[message.text] else {
      XCTFail("diagnostic '\(message.text)' not raised", file: file, line: line)
      return
    }
    guard diag == times else {
      XCTFail(
        "diagnostic '\(message.text)' raised \(diag) times; expected \(times)",
        file: file,
        line: line
      )
      return
    }
    consumer.registeredDiagnostics[message.text] = diag - 1
  }
}
