import Foundation
import SwiftSyntax

/// Splits variable declarations with multiple bindings into separate variable
/// declarations with a single binding in each of them, with the same modifier
/// as the multiple-binding version.
///
/// ```
/// var a = 3, (b, c) = (2, 3), g = "hello"
/// ```
/// converts to
/// ```
/// var a = 3
/// var (b, c) = (2, 3)
/// var g = "hello"
/// ```
public final class SplitVariableDeclarationsRewriter: SyntaxRewriter {
  public override func visit(_ node: CodeBlockSyntax) -> Syntax {
    var newItems = [CodeBlockItemSyntax]()
    for codeBlockItem in node.statements {
      if let varDecl = codeBlockItem.item as? VariableDeclSyntax {
        for binding in varDecl.bindings {
          let newBinding = binding.withTrailingComma(nil)
          let newDecl = varDecl.withBindings(
            SyntaxFactory.makePatternBindingList([newBinding]))
          newItems.append(codeBlockItem.withItem(newDecl))
        }
        continue
      }
      let newUnderlyingItem = visit(codeBlockItem.item)
      newItems.append(codeBlockItem.withItem(newUnderlyingItem))
    }
    return super.visit(node.withStatements(
      SyntaxFactory.makeCodeBlockItemList(newItems)))
  }
}
