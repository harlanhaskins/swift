import SwiftSyntax

extension Diagnostic.Message {
    /// Prepends the name of a rule to this diagnostic message.
    /// - parameter rule: The rule whose name will be prepended to the diagnostic.
    /// - returns: A new `Diagnostic.Message` with the name of the provided rule prepended.
    public func withRule(_ rule: Rule) -> Diagnostic.Message {
        return .init(severity, "[\(rule.ruleName)]: \(text)")
    }
}
