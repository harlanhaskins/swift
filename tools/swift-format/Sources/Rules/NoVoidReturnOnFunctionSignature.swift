import Core
import SwiftSyntax

/// Functions that return `()` or `Void` should omit the return signature.
///
/// Lint: Function declarations that explicitly return `()` or `Void` will yield a lint error.
///
/// Format: Function declarations with explicit returns of `()` or `Void` will have their return
///         signature stripped.
///
/// - SeeAlso: https://google.github.io/swift#types-with-shorthand-names
public final class NoVoidReturnOnFunctionSignature: SyntaxFormatRule {
  /// Remove the `-> Void` return type for function signatures. Do not remove
  /// it for closure signatures, because that may introduce an ambiguity when closure signatures
  /// are inferred.
  public override func visit(_ node: FunctionSignatureSyntax) -> Syntax {
    if let ret = node.output?.returnType as? SimpleTypeIdentifierSyntax, ret.name.text == "Void" {
      // TODO(b/77534297): location for diagnostic
      diagnose(.removeRedundantReturn("Void"), location: nil)
      return node.withOutput(nil)
    }
    if let tup = node.output?.returnType as? TupleTypeSyntax, tup.elements.isEmpty {
      // TODO(b/77534297): location for diagnostic
      diagnose(.removeRedundantReturn("()"), location: nil)
      return node.withOutput(nil)
    }
    return node
  }
}

extension Diagnostic.Message {
  static func removeRedundantReturn(_ type: String) -> Diagnostic.Message {
    return .init(.warning, "remove explicit '\(type)' return type")
  }
}
