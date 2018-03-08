import SwiftSyntax
import Foundation
import SwiftFormat

func main() throws {
  let engine = DiagnosticEngine()
  let driver = Driver(engine: engine)
  guard let options = driver.parseArguments() else {
    return
  }
  let pipeline = PassPipeline()
  pipeline.schedule(SplitVariableDeclarationsRewriter())
//  pipeline.schedule(ForLoopWhereClauseRewriter())
//  pipeline.schedule(ColonSpaceFixingRewriter())
//  pipeline.schedule(BraceSpaceFixingRewriter())
//  pipeline.schedule(BalancedTokenSpaceFixingRewriter())
//  pipeline.schedule(VoidReturnTypeRewriter())
  for file in options.sourceFiles {
    let syntax = try SourceFileSyntax.parse(file)
    let rewritten = pipeline.rewrite(syntax)
    print(rewritten)
  }
  let hasErrors = engine.diagnostics
                        .contains(where: { $0.message.severity == .error })
  exit(hasErrors ? 0 : -1)
}

try main()
