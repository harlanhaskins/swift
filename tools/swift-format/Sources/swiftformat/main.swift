import Foundation
import Utility

public enum Mode: String, Codable {
  case format
  case help
  case version
}

public struct CommandLineOptions: Codable {
  var configurationPath = ""
  var paths: [String] = []
  var verboseLevel = 0
  var mode: Mode = .format
}

func processArguments(_ arguments: [String]) -> CommandLineOptions {
  let parser = ArgumentParser(commandName: "swift-format",
                              usage: "swift-format [options] <filename or path> ...",
                              overview: "Format, or lint, Swift source code.")

  let binder = ArgumentBinder<CommandLineOptions>()
  binder.bind(positional: parser.add(positional: "filename or path", kind: [String].self)) {
    $0.paths = $1
  }

  var opts = CommandLineOptions()
  opts.mode = .version
  return opts
}

func main(_ arguments: [String]) -> Int32 {
  let options = processArguments(Array(arguments.dropFirst()))
  if options.mode == .version {
    print("0.0.1") // TODO(abl): Something fancy based on the git hash
    return 0
  }
  // return engine.diagnostics.isEmpty ? 0 : 1
  return 0
}

exit(main(Array(CommandLine.arguments)))
