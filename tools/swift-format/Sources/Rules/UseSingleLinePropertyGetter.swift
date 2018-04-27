import Core
import Foundation
import SwiftSyntax

/// Read-only computed properties must use implicit `get` blocks.
///
/// Lint: Read-only computed properties with explicit `get` blocks yield a lint error.
///
/// Format: Explicit `get` blocks are rendered implicit by removing the `get`.
///
/// - SeeAlso: https://google.github.io/swift#properties-2
public final class UseSingleLinePropertyGetter: SyntaxFormatRule {

  public override func visit(_ node: AccessorBlockSyntax) -> Syntax {
    guard
      let accessorList = node.accessorListOrStmtList as? AccessorListSyntax,
      let acc = accessorList.first,
      let body = acc.body,
      accessorList.count == 1,
      acc.accessorKind.tokenKind == .contextualKeyword("get")
    else { return node }

    diagnose(.removeExtraneousGetBlock, on: acc)

    return node.withAccessorListOrStmtList(body.statements)
  }
}

extension Diagnostic.Message {
  static let removeExtraneousGetBlock =
    Diagnostic.Message(.warning, "remove extraneous 'get {}' block")
}
