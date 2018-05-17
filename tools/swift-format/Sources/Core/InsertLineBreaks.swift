import Configuration
import SwiftSyntax

// TODO(harlan): Comment this whole file.

public enum BreakStyle {
  /// A consistent break indicates that the break will always be finalized as a newline
  /// if wrapping occurs.
  case consistent

  /// Inconsistent breaks will only be expressed as a newline if they're required to be wrapped as
  /// their addition to the line would go past the line length limit.
  case inconsistent
}

public struct Comment {
  enum Kind {
    case line, docLine, block, docBlock
  }
  public let text: String

  func reflow(lineLength: Int) -> [Comment] {
    return []
  }
}

public enum Token: Hashable {
  case comment(String, hasTrailingSpace: Bool)
  case newlines(Int)
  case `break`(BreakStyle, spaces: Int)
  case open(Indent)
  case close
  case syntax(TokenSyntax)

  static let newline = Token.newlines(1)
  static let `break` = Token.break(.inconsistent, spaces: 0)

  var isOpen: Bool {
    if case .open = self { return true }
    return false
  }
}

extension Indent {
  var character: Character {
    switch kind {
    case .tabs: return "\t"
    case .spaces: return " "
    }
  }

  var text: String {
    return String(repeating: character, count: count)
  }

  func length(in configuration: Configuration) -> Int {
    switch kind {
    case .spaces: return count
    case .tabs: return count * configuration.tabWidth
    }
  }
}

extension Array where Element == Indent {
  func indentation() -> String {
    return map { $0.text }.joined()
  }

  func length(in configuration: Configuration) -> Int {
    return reduce(into: 0) { $0 += $1.length(in: configuration) }
  }
}

public class PrettyPrinter {
  public let configuration: Configuration
  private var stream: [Token]
  private var tokens = [Token]()
  private var bufferIndent = [Indent]()
  private var outputIndent = [Indent]()
  private var forceWrapping = [Bool]()
  private var lineLength = 0
  private var maxLineLength: Int

  private var requiresIndent = false

  public init(configuration: Configuration, stream: [Token]) {
    self.configuration = configuration
    self.stream = stream
    self.maxLineLength = configuration.lineLength
  }

  func columns(_ token: Token) -> Int {
    switch token {
    case .comment(let line, let hasTrailingSpace):
      return line.count + (hasTrailingSpace ? 1 : 0)
    case .break(_, let spaces):
      return spaces
    case .newlines: return 0
    case .open, .close: return 0
    case .syntax(let token):
      return token.text.count + (token.trailingTrivia.hasSpaces ? 1 : 0)
    }
  }

  func write(_ str: String) {
    print(str, terminator: "")
  }

  func adjustLineLength(_ token: Token) {
    if case .newlines = token {
      lineLength = 0
    } else {
      lineLength += columns(token)
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

    if lineLength + columns(token) > maxLineLength {
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
      switch /* no */ token {
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
        writeIndent()
        write(comment)
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

/// InsertLineBreaks inserts line breaks as appropriate into a flattened list of Syntax tokens.
public final class InsertLineBreaks {
  public let tokens: [Token]

  init(tokens: [Token]) {
    self.tokens = tokens
  }
}
