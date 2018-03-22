import Core
import Foundation
import SwiftSyntax

/// Static properties of a type that return that type should not include a reference to their type.
///
/// "Reference to their type" means that the property name includes part, or all, of the type. If
/// the type contains a namespace (i.e. `UIColor`) the namespace is ignored;
/// `public class var redColor: UIColor` would trigger this rule.
///
/// Lint: Static properties of a type that return that type will yield a lint error.
///
/// - SeeAlso: https://google.github.io/swift#static-and-class-properties
public final class DontRepeatTypeInStaticProperties: SyntaxLintRule {

}
