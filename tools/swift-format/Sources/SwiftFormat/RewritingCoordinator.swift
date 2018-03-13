import Foundation
import SwiftSyntax

/// Keeps track of a set of in-flight transformations for certain kinds of
/// Syntax nodes. In a single walk of the tree, performs all rewriting
/// operations that apply to each node and rebuilds the tree afterwards.
public final class RewritingCoordinator: SyntaxRewriter {
  /// A hashable wrapper for a Syntax node's metatype. This is used to register
  /// rewriting operations for a given Syntax node. We're using the fact that
  /// type metadata is guaranteed to be pointer-equal for class types.
  struct SyntaxType: Hashable {
    let type: Syntax.Type
    static func ==(lhs: SyntaxType, rhs: SyntaxType) -> Bool {
      return ObjectIdentifier(lhs.type) == ObjectIdentifier(rhs.type)
    }
    var hashValue: Int {
      return ObjectIdentifier(type).hashValue
    }
  }

  /// Keep a map of rewrite rules based on the type of syntax node. These
  /// rewriters _must_ be able to perform their rewriting with just a single
  /// `visit` method for the type they are mapped to in this dictionary.
  private var rewriteRules = [SyntaxType: [SyntaxRewriter]]()

  private func rules(for node: Syntax) -> [SyntaxRewriter] {
    let nodeType = SyntaxType(type: type(of: node))
    return rewriteRules[nodeType, default: []]
  }

  public func register(_ rewriter: SyntaxRewriter,
                       for nodeTypes: Syntax.Type...) {
    for nodeType in nodeTypes {
      let nodeTypeWrapper = SyntaxType(type: nodeType)
      rewriteRules[nodeTypeWrapper, default: []].append(rewriter)
    }
  }

  public /* FIXME(hbh): override */ func visitAny(_ node: Syntax) -> Syntax {
    return rules(for: node).reduce(super.visit(node)) { node, rewriter in
      rewriter.visit(node)
    }
  }
}
