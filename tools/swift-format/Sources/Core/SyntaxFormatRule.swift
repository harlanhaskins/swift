import SwiftSyntax

open class SyntaxFormatRule: SyntaxRewriter, Rule {
  public let context: Context

  public required init(context: Context) {
    self.context = context
  }
}
