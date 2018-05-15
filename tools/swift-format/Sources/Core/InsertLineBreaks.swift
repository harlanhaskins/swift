import Configuration
import SwiftSyntax

public enum Token: Hashable {
  case comment(String)
  case newline
  case emptyLine
  case openBreak
  case closeBreak
  case syntax(TokenSyntax)
}

public struct PrettyPrinter {
  public let configuration: Configuration
  public init(configuration: Configuration) {
    self.configuration = configuration
  }

  public func printStream(_ tokens: [Token]) {
    var indent = 0

    var requiresIndent = false
    func write(_ str: String) {
      print(str, terminator: "")
    }
    func addIndent() {
      if requiresIndent {
        write(String(repeating: " ", count: indent))
      }
      requiresIndent = false
    }
    for tok in tokens {
      switch tok {
      case .comment(let comment):
        addIndent()
        write(comment)
      case .newline:
        write("\n")
        requiresIndent = true
      case .emptyLine:
        write(String(repeating: "\n", count: configuration.maximumBlankLines + 1))
        requiresIndent = true
      case .openBreak:
        indent += 2
        write("⟨")
      case .closeBreak:
        indent -= 2
        write("⟩")
      case .syntax(let tok):
        addIndent()
        write(tok.text)
        write(String(repeating: " ", count: tok.trailingTrivia.numberOfSpaces))
      }
    }
  }
}

/// InsertLineBreaks inserts line breaks as appropriate into a flattened list of Syntax tokens.
public final class InsertLineBreaks {
  public let tokens: [Token]

  init(tokens: [Token]) {
    self.tokens = tokens
  }
}
