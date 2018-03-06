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
}

extension TokenSyntax {
  /// Recursively walks through the tree to find the next token semantically
  /// after this token.
  var nextToken: TokenSyntax? {
    var current: Syntax? = self

    /// Walk up the parent chain, checking adjacent siblings after each node
    /// until we find a node with a 'first token'.
    while let node = current {
      let nextChild = node.parent?.child(at: node.indexInParent + 1)
      if let child = nextChild?.firstToken { return child }
      current = node.parent
    }
    return nil
  }
}
