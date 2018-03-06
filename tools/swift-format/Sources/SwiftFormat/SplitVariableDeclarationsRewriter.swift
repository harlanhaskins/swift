import Foundation
import SwiftSyntax

public final class SplitVariableDeclarationsRewriter: SyntaxRewriter {
  public override func visit(_ node: CodeBlockSyntax) -> Syntax {
    var newItems = [CodeBlockItemSyntax]()
    for codeBlockItem in node.statements {
      if let varDecl = codeBlockItem.item as? VariableDeclSyntax {
        for binding in varDecl.bindings {
          let newDecl = varDecl.withBindings(
            SyntaxFactory.makePatternBindingList([binding]))
          newItems.append(codeBlockItem.withItem(newDecl))
        }
        continue
      }
      newItems.append(codeBlockItem)
    }
    return node.withStatements(
      SyntaxFactory.makeCodeBlockItemList(newItems))
  }
}
