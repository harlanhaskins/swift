import Foundation
import SwiftSyntax

extension TokenKind {
  /// Whether this token is the 'left' token of a pair of balanced
  /// delimiters (paren, angle bracket, square bracket.)
  var isLeftBalancedDelimiter: Bool {
    switch self {
    case .leftParen, .leftAngle, .leftSquareBracket:
      return true
    default:
      return false
    }
  }

  /// Whether this token is the 'right' token of a pair of balanced
  /// delimiters (paren, angle bracket, square bracket.)
  var isRightBalancedDelimiter: Bool {
    switch self {
    case .rightParen, .rightAngle, .rightSquareBracket:
      return true
    default:
      return false
    }
  }
}

/// Ensures there are no spaces on the inside of a pair of balanced delimiters
/// like parentheses, angle brackets, and square brackets, when they appear
/// on the same line as the next token.
///
/// ```
/// print( i )
/// ```
/// converts to
/// ```
/// print(i)
/// ```
public final class BalancedTokenSpaceFixingRewriter: SyntaxRewriter {
  public override func visit(_ token: TokenSyntax) -> Syntax {
    // Ensure we have an adjacent token on the same line
    guard let next = token.nextToken else { return token }
    if next.leadingTrivia.containsNewlines { return token }

    // If either this current token in a left delimiter, or the next token
    // is a right delimiter, then remove spaces from our trailing trivia.
    if token.tokenKind.isLeftBalancedDelimiter ||
       next.tokenKind.isRightBalancedDelimiter {
      return token.withTrailingTrivia(token.trailingTrivia.withoutSpaces())
    }
    return token
  }
}
