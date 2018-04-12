import Configuration
import Core
import Foundation
import Rules
import SwiftSyntax

/// Creates a Pipeline with the provided configuration, diagnostic engine, and context.
///
/// This function creates a Pipeline object and registers all known formatting/linting passes with
/// that pipeline.
func createPipeline(
  configuration: Configuration,
  diagnosticEngine: DiagnosticEngine?,
  file: URL,
  mode: Pipeline.Mode
) -> Pipeline {
  let context = Context(
    configuration: configuration,
    diagnosticEngine: diagnosticEngine,
    fileURL: file
  )
  let consumer = PrintingDiagnosticConsumer()
  context.diagnosticEngine?.addConsumer(consumer)
  let pipeline = Pipeline(context: context, mode: mode)

  populate(pipeline)

  return pipeline
}

/// Runs the linting pipeline over the provided source file.
///
/// If there were any lint diagnostics emitted, this function returns a non-zero exit code.
/// - Parameter path: The absolute path to the source file to be linted.
/// - Returns: Zero if there were no lint errors, otherwise a non-zero number.
public func lintMain(path: String) -> Int {
  let url = URL(fileURLWithPath: path)
  let engine = DiagnosticEngine()
  let pipeline = createPipeline(
    configuration: Configuration(),
    diagnosticEngine: engine,
    file: url,
    mode: .lint
  )
  do {
    let file = try SourceFileSyntax.parse(url)

    // Important! We need to cast this to Syntax to avoid going directly into the specialized
    // version of visit(_: SourceFileSyntax), which will not run the pipeline properly.
    _ = pipeline.visit(file as Syntax)
  } catch {
    fatalError("\(error)")
  }
  return engine.diagnostics.isEmpty ? 0 : 1
}

/// Runs the formatting pipeline over the provided source file.
///
/// - Parameter path: The absolute path to the source file to be linted.
/// - Returns: Zero if there were no lint errors, otherwise a non-zero number.
public func formatMain(path: String) -> Int {
  let url = URL(fileURLWithPath: path)
  let pipeline = createPipeline(
    configuration: Configuration(),
    diagnosticEngine: nil,
    file: url,
    mode: .format
  )
  do {
    let file = try SourceFileSyntax.parse(url)

    // Important! We need to cast this to Syntax to avoid going directly into the specialized
    // version of visit(_: SourceFileSyntax), which will not run the pipeline properly.
    let formatted = pipeline.visit(file as Syntax)
    let output = url.deletingPathExtension().appendingPathExtension("formatted.swift")
    try formatted.description.write(to: output, atomically: true, encoding: .utf8)
  } catch {
    fatalError("\(error)")
  }
  return 0
}
