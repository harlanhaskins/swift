import Foundation
import SwiftSyntax

extension Syntax {
  /// Performs a depth-first in-order traversal of the node to find the first
  /// node in its hierarchy that is a Token.
  var firstToken: TokenSyntax? {
    if let tok = self as? TokenSyntax { return tok }
    for child in children {
      if let tok = child.firstToken { return tok }
    }
    return nil
  }

  var lastToken: TokenSyntax? {
    if let tok = self as? TokenSyntax { return tok }
    for child in children.reversed() {
      if let tok = child.lastToken { return tok }
    }
    return nil
  }

  /// Walks up from the current node to find the nearest node that is an
  /// Expr, Stmt, or Decl.
  var containingExprStmtOrDecl: Syntax? {
    var node: Syntax? = self
    while let parent = node?.parent {
      if parent is ExprSyntax ||
         parent is StmtSyntax ||
         parent is DeclSyntax {
        return parent
      }
      node = parent
    }
    return nil
  }

  /// Recursively walks through the tree to find the next token semantically
  /// after this node.
  var nextToken: TokenSyntax? {
    var current: Syntax? = self
    
    // Walk up the parent chain, checking adjacent siblings after each node
    // until we find a node with a 'first token'.
    while let node = current {
      // If we've walked to the top, just stop.
      guard let parent = node.parent else { break }

      // If we're not the last child, search through each sibling until
      // we find a token.
      if node.indexInParent < parent.numberOfChildren {
        for idx in (node.indexInParent + 1)..<parent.numberOfChildren {
          let nextChild = parent.child(at: idx)

          // If there's a token, we're good.
          if let child = nextChild?.firstToken { return child }
        }
      }

      // If we've exhausted siblings, move up to the parent.
      current = parent
    }
    return nil
  }
}

extension TokenSyntax {
  /// Returns this token with only one space at the end of its trailing trivia.
  func withOneTrailingSpace() -> TokenSyntax {
    return withTrailingTrivia(trailingTrivia.withOneTrailingSpace())
  }

  /// Returns this token with only one space at the beginning of its leading
  /// trivia.
  func withOneLeadingSpace() -> TokenSyntax {
    return withLeadingTrivia(leadingTrivia.withOneLeadingSpace())
  }

  /// Returns this token with only one newline at the end of its leading trivia.
  func withOneTrailingNewline() -> TokenSyntax {
    return withTrailingTrivia(trailingTrivia.withOneTrailingNewline())
  }

  /// Returns this token with only one newline at the beginning of its leading
  /// trivia.
  func withOneLeadingNewline() -> TokenSyntax {
    return withLeadingTrivia(leadingTrivia.withOneLeadingNewline())
  }
}
