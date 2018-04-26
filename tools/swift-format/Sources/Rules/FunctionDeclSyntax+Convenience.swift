import SwiftSyntax

extension FunctionDeclSyntax {
  /// Constructs a name for a function that includes parameter labels, i.e. `foo(_:bar:)`.
  var fullDeclName: String {
    let params = signature.input.parameterList.map { param in
      "\(param.firstName?.text ?? "_"):"
    }
    return "\(identifier.text)(\(params.joined()))"
  }
}
