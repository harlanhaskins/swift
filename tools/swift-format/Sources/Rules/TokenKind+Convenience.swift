import SwiftSyntax

extension TokenKind {
  /// Whether this token is the 'left' token of a pair of balanced
  /// delimiters (paren, angle bracket, square bracket.)
  var isLeftBalancedDelimiter: Bool {
    switch self {
    case .leftParen, .leftSquareBracket, .leftAngle:
      return true
    default:
      return false
    }
  }

  /// Whether this token is the 'right' token of a pair of balanced
  /// delimiters (paren, angle bracket, square bracket.)
  var isRightBalancedDelimiter: Bool {
    switch self {
    case .rightParen, .rightSquareBracket, .rightAngle:
      return true
    default:
      return false
    }
  }
}
