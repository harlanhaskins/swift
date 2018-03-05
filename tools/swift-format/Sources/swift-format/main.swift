import SwiftSyntax
import Foundation

func main() {
  let engine = DiagnosticEngine()
  let driver = Driver(engine: engine)
  guard let options = driver.parseArguments() else {
    return
  }
  print(options.sourceFiles)
  exit(engine.)
}

main()
