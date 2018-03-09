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
  public func splitVariableDecls(
    _ items: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
    var newItems = [CodeBlockItemSyntax]()
    for codeBlockItem in items {
      if let varDecl = codeBlockItem.item as? VariableDeclSyntax {
        // The first binding corresponds to the original `var`/`let`
        // declaration, so it should not have its trivia replaced.
        var isFirst = true
        for binding in varDecl.bindings {
          let newBinding = binding.withTrailingComma(nil)
          let newDecl = varDecl.withBindings(
            SyntaxFactory.makePatternBindingList([newBinding]))
          var finalDecl: Syntax = newDecl
          // Only add a newline if this is a brand new binding.
          if !isFirst {
            let firstTok = newDecl.firstToken
            let origLeading = firstTok?.leadingTrivia.withoutNewlines() ?? []
            finalDecl =
              ReplaceTriviaRewriter(
                token: newDecl.firstToken,
                leadingTrivia: .newlines(1) + origLeading)
              .visit(finalDecl)
          }
          newItems.append(codeBlockItem.withItem(finalDecl))
          isFirst = false
        }
        continue
      }
      let newUnderlyingItem = visit(codeBlockItem.item)
      newItems.append(codeBlockItem.withItem(newUnderlyingItem))
    }
    return SyntaxFactory.makeCodeBlockItemList(newItems)
  }

  public override func visit(_ node: CodeBlockSyntax) -> Syntax {
    let newStmts = splitVariableDecls(node.statements)
    return super.visit(node.withStatements(newStmts))
  }

  public override func visit(_ node: SourceFileSyntax) -> Syntax {
    let newStmts = splitVariableDecls(node.statements)
    return super.visit(node.withStatements(newStmts))
  }
}
