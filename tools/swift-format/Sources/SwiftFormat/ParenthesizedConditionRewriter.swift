import Foundation
import SwiftSyntax

public final class ParenthesizedConditionRewriter: SyntaxRewriter {
  public override func visit(_ node: ConditionElementSyntax) -> Syntax {
    guard let paren = node.condition as? ExprSyntax else {
      return node
    }
    print(type(of: node.condition))
    return node
  }
}
