import SwiftSyntax

/// SyntaxType is a small wrapper around a metatype of the Syntax protocol that allows for easy
/// hashing and ==.
struct SyntaxType: Hashable {
  let type: Syntax.Type

  static func ==(lhs: SyntaxType, rhs: SyntaxType) -> Bool {
    return ObjectIdentifier(lhs.type) == ObjectIdentifier(rhs.type)
  }

  var hashValue: Int {
    return ObjectIdentifier(type).hashValue
  }
}
