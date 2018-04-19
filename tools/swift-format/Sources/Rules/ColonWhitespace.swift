import Core
import Foundation
import SwiftSyntax

/// Enforces restrictions on whitespace before and after colons.
///
/// Exactly zero spaces must appear before each colon, and exactly one space after, if not at the
/// end of a line.
///
/// Lint: If an invalid number of spaces appear before or after a colon, a lint error is
///       raised.
///
/// Format: All colons will have no spaces before, and a single space after.
///
/// - SeeAlso: https://google.github.io/swift#horizontal-whitespace
public final class ColonWhitespace: SyntaxFormatRule {
  public override func visit(_ token: TokenSyntax) -> Syntax {
    guard let next = token.nextToken else { return token }

    /// Colons own their trailing spaces, so ensure it only has 1 if there's
    /// another token on the same line.
    if token.tokenKind == .colon,
       !next.leadingTrivia.containsNewlines {
      let numSpaces = token.trailingTrivia.numberOfSpaces
      if numSpaces > 1 {
        // TODO(b/77534297): location for diagnostic
        diagnose(.removeSpacesAfterColon(count: numSpaces - 1), location: nil)
      }
      if numSpaces == 0 {
        // TODO(b/77534297): location for diagnostic
        diagnose(.addSpaceAfterColon, location: nil)
      }
      return token.withOneTrailingSpace()
    }

    /// Otherwise, colon-adjacent tokens should have 0 spaces after.
    if next.tokenKind == .colon, token.trailingTrivia.containsSpaces {
      // TODO(b/77534297): location for diagnostic
      diagnose(.noSpacesBeforeColon, location: nil)
      return token.withTrailingTrivia(token.trailingTrivia.withoutSpaces())
    }
    return token
  }
}

extension Diagnostic.Message {
  static func removeSpacesAfterColon(count: Int) -> Diagnostic.Message {
    let ending = count == 1 ? "" : "s"
    return Diagnostic.Message(.warning, "remove \(count) space\(ending) after ':'")
  }

  static let addSpaceAfterColon =
    Diagnostic.Message(.warning, "add one space after ':'")
  static let noSpacesBeforeColon =
    Diagnostic.Message(.warning, "remove spaces before ':'")
}
