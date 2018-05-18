import Configuration
import Core
import SwiftSyntax

enum BreakStyle {
  /// A consistent break indicates that the break will always be finalized as a newline
  /// if wrapping occurs.
  case consistent

  /// Inconsistent breaks will only be expressed as a newline if they're required to be wrapped as
  /// their addition to the line would go past the line length limit.
  case inconsistent
}

enum Token {
  case comment(Comment, hasTrailingSpace: Bool)
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

  var columns: Int {
    switch self {
    case .comment(let comment, let hasTrailingSpace):
      return (comment.text.split(separator: "\n").first?.count ?? 0) + (hasTrailingSpace ? 1 : 0)
    case .break(_, let spaces):
      return spaces
    case .newlines: return 0
    case .open, .close: return 0
    case .syntax(let token):
      return token.text.count + (token.trailingTrivia.hasSpaces ? 1 : 0)
    }
  }
}
