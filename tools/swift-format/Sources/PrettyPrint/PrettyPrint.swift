import Configuration
import Core
import SwiftSyntax

// TODO(harlan): Comment this whole file.

/// PrettyPrinter takes a Syntax node and outputs a well-formatted, reindented reproduction of the
/// code to stdout.
public class PrettyPrinter {
  private let configuration: Configuration
  private var stream: [Token]
  private var tokens = [Token]()
  private var bufferIndent = [Indent]()
  private var outputIndent = [Indent]()
  private var forceWrapping = [Bool]()
  private var lineLength = 0
  private var maxLineLength: Int

  private var requiresIndent = false

  /// Creates a new PrettyPrinter with the provided formatting configuration.
  ///
  /// - Parameters:
  ///   - configuration: The configuration used to decide whitespace or breaking behavior.
  ///   - node: The node to be pretty printed.
  public init(configuration: Configuration, node: Syntax) {
    self.configuration = configuration
    self.stream = node.makeTokenStream(configuration: configuration)
    self.maxLineLength = configuration.lineLength
  }

  func write<S: StringProtocol>(_ str: S) {
    print(str, terminator: "")
  }

  func adjustLineLength(_ token: Token) {
    if case .newlines = token {
      lineLength = 0
    } else {
      lineLength += token.columns
    }
  }

  func appendToken(_ token: Token) {
    adjustLineLength(token)
    tokens.append(token)
  }

  func addToken(_ token: Token) {
    if case .newlines = token {
      appendToken(token)
      flush(forceWrapped: false)
      return
    }

    if lineLength + token.columns > maxLineLength {
      flush(forceWrapped: true)
      if case .break(.inconsistent, _) = token {
        appendToken(.newline)
      } else {
        appendToken(token)
      }
    } else {
      appendToken(token)
    }
  }

  /** Test
   */
  public func prettyPrint() {
    for token in stream {
      switch token {
      case .open(let i):
        addToken(token)
        addIndent(i)
      case .close:
        addToken(token)
        removeIndent()
      default:
        addToken(token)
      }
    }
    addToken(.newline)
    flush(forceWrapped: false)
  }

  func recomputeMaxLength() {
    maxLineLength = configuration.lineLength - bufferIndent.length(in: configuration)
  }

  func addIndent(_ level: Indent) {
    bufferIndent.append(level)
    recomputeMaxLength()
  }

  func removeIndent() {
    bufferIndent.removeLast()
    recomputeMaxLength()
  }

  func writeNewlines(_ count: Int = 1) {
    write(String(repeating: "\n", count: count))
    requiresIndent = true
  }

  func writeIndent() {
    if requiresIndent {
      write(outputIndent.indentation())
    }
    requiresIndent = false
  }

  func flush(forceWrapped: Bool) {
    let endOfFlushBuffer: Int
    let mostRecentOpen = tokens.index(where: { $0.isOpen })
    if forceWrapped, let openIdx = mostRecentOpen {
      endOfFlushBuffer = openIdx
    } else {
      endOfFlushBuffer = tokens.count
    }
    for tok in tokens[0..<endOfFlushBuffer] {
      switch tok {
      case .comment(let comment, let hasTrailingSpace):
        let lines = comment.wordWrap(lineLength: maxLineLength - lineLength)
        for (offset, line) in lines.enumerated() {
          if requiresIndent {
            write(outputIndent.indentation())
          }
          write(line)
          if offset < lines.count - 1 {
            write("\n")
          }
        }
        requiresIndent = false
        if hasTrailingSpace {
          write(" ")
        }
      case .newlines(let n):
        writeNewlines(n)
      case .syntax(let tok):
        writeIndent()
        if tok.leadingTrivia.hasBackticks {
          write("`")
        }
        write(tok.text)
        if tok.trailingTrivia.hasBackticks {
          write("`")
        }
        if tok.trailingTrivia.hasSpaces {
          write(" ")
        }
      case .break(let style, let spaces):
        if let wrap = forceWrapping.last, wrap, style == .consistent {
          writeNewlines()
        } else if spaces > 0 {
          write(String(repeating: " ", count: spaces))
        }
      case .open(let indent):
        outputIndent.append(indent)
      case .close:
        outputIndent.removeLast()
        if !forceWrapping.isEmpty {
          forceWrapping.removeLast()
        }
      }
    }
    tokens.removeSubrange(0..<endOfFlushBuffer)
    if mostRecentOpen != nil {
      forceWrapping.append(forceWrapped)
      lineLength = 0
      tokens.forEach(adjustLineLength)
    }
  }
}
