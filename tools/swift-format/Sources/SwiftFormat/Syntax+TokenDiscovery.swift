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
}

extension TokenSyntax {
  /// Recursively walks through the tree to find the next token semantically
  /// after this token.
  var nextToken: TokenSyntax? {
    var current: Syntax? = self
    
    // Walk up the parent chain, checking adjacent siblings after each node
    // until we find a node with a 'first token'.
    while let node = current {
      // FIXME(hbh): This is not the best way to do this. The best way is to
      //             iterate over each child, rather than stopping at the first
      //             `nil` child.
      // Ask for the next sibling in this parent's children list.
      let nextChild = node.parent?.child(at: node.indexInParent + 1)

      // If there's a token, we're good.
      if let child = nextChild?.firstToken { return child }

      // Otherwise, start searching the sibling. If we've exhausted siblings,
      // move up to the parent.
      current = nextChild ?? node.parent
    }
    return nil
  }
}
