import Foundation

struct Comment {
  enum Kind {
    case line, docLine, block, docBlock

    /// The length of the characters starting the comment.
    var prefixLength: Int {
      switch self {
      // `//`, `/*`, and `/**` all will have their continued lines prefixed with 3 characters.
      case .line, .block, .docBlock: return 2

      // `/// ` is 4 characters.
      case .docLine: return 3
      }
    }

    var prefix: String {
      switch self {
      case .line: return "//"
      case .block, .docBlock: return " *"
      case .docLine: return "///"
      }
    }
  }
  let kind: Kind
  var text: String

  init(kind: Kind, text: String) {
    self.text = text
    self.kind = kind

    self.text.removeFirst(kind.prefixLength)

    switch kind {
    case .docBlock:
      self.text.removeLast(2)
    case .block:
      self.text.removeLast(2)
    default: break
    }
  }

  mutating func addText(_ text: String) {
    self.text += "\n" + text
  }

  func wordWrap(lineLength: Int) -> [String] {
    let maxLength = lineLength - (kind.prefixLength + 1)
    let scanner = Scanner(string: text)
    var lines = [String]()
    var currentLine = ""
    var currentLineLength = 0
    var buffer: NSString! = ""
    while scanner.scanUpToCharacters(from: .whitespacesAndNewlines, into: &buffer) {
      let strBuf = buffer as String
      if currentLineLength + strBuf.count > maxLength {
        lines.append(currentLine)
        currentLine = ""
        currentLineLength = 0
      }
      currentLine += strBuf + " "
      currentLineLength += strBuf.count + 1
    }
    if currentLineLength > 0 {
      lines.append(currentLine)
    }
    for i in 0..<lines.count {
      lines[i] = "\(kind.prefix) \(lines[i])"
    }
    switch kind {
    case .block:
      lines.insert("/*", at: 0)
      lines.append(" */")
    case .docBlock:
      lines.insert("/**", at: 0)
      lines.append(" */")
    default: break
    }
    return lines
  }
}
