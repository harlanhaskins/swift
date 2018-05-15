import Configuration
import SwiftSyntax

private final class TokenStreamCreator: SyntaxVisitor {
  private var tokens = [Token]()
  private let config: Configuration

  init(configuration: Configuration) {
    self.config = configuration
  }

  func makeStream(from node: Syntax) -> [Token] {
    visit(node)
    defer { tokens = [] }
    return tokens
  }

  func isControlFlow(_ node: Syntax?) -> Bool {
    guard let node = node else { return false }
    return node is IfStmtSyntax ||
      node is WhileStmtSyntax ||
      node is GuardStmtSyntax ||
      node is ForInStmtSyntax ||
      node is SwitchStmtSyntax
  }

  func shouldOpenBreak(_ token: TokenSyntax) -> Bool {
    switch token.tokenKind {
    case .leftBrace, .leftParen, .leftAngle, .leftSquareBracket: return true
    case .ifKeyword, .forKeyword, .guardKeyword, .whileKeyword, .switchKeyword: return true
    case .colon where token.parent is SwitchCaseLabelSyntax: return true
    default: return false
    }
  }

  func shouldCloseBreak(_ token: TokenSyntax) -> Bool {
    switch token.tokenKind {
    case .rightBrace, .rightParen, .rightAngle, .rightSquareBracket: return true
    case .caseKeyword where token.parent is SwitchCaseLabelSyntax: return true
    case .leftBrace where isControlFlow(token.containingExprStmtOrDecl): return true
    default: return false
    }
  }

  override func visit(_ token: TokenSyntax) {
    breakDownTrivia(token.leadingTrivia)
    if shouldCloseBreak(token) {
      tokens.append(.closeBreak)
    }
    tokens.append(.syntax(token))
    if shouldOpenBreak(token) {
      tokens.append(.openBreak)
    }
    breakDownTrivia(token.trailingTrivia)
  }

  private func breakDownTrivia(_ trivia: Trivia) {
    let onlyNewlinesAndComments = Trivia(pieces: trivia.filter {
      switch $0 {
      case .spaces, .tabs, .verticalTabs, .formfeeds: return false
      default: return true
      }
    }).condensed()
    for piece in onlyNewlinesAndComments {
      switch piece {
      case .blockComment(let text),
           .lineComment(let text),
           .docLineComment(let text),
           .docBlockComment(let text):
        tokens.append(.comment(text))
      case .newlines(let n), .carriageReturns(let n), .carriageReturnLineFeeds(let n):
        if n <= config.maximumBlankLines {
          for _ in 0..<n {
            tokens.append(.newline)
          }
        } else {
          tokens.append(.emptyLine)
        }
      default:
        break
      }
    }
  }
}

extension Syntax {
  public func makeTokenStream(configuration: Configuration) -> [Token] {
    return TokenStreamCreator(configuration: configuration).makeStream(from: self)
  }
}
