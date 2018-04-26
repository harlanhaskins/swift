import SwiftSyntax

extension ModifierListSyntax {
  func has(modifier: String) -> Bool {
    return contains { $0.name.text == modifier }
  }
}
