import Foundation
import SwiftSyntax

extension TokenKind {
  var isLeftBalancedDelimiter: Bool {
    switch self {
    case .leftParen, .leftAngle, .leftSquareBracket:
      return true
    default:
      return false
    }
  }
  var isRightBalancedDelimiter: Bool {
    switch self {
    case .rightParen, .rightAngle, .rightSquareBracket:
      return true
    default:
      return false
    }
  }
}

public final class BalancedTokenSpaceFixingRewriter: SyntaxRewriter {
  public override func visit(_ token: TokenSyntax) -> Syntax {
    guard let next = token.nextToken else { return token }
    if next.leadingTrivia.containsNewlines { return token }
    if token.tokenKind.isLeftBalancedDelimiter ||
       next.tokenKind.isRightBalancedDelimiter {
      return token.withTrailingTrivia(token.trailingTrivia.withoutSpaces())
    }
    return token
  }
}
