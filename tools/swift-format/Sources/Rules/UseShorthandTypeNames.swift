import Core
import Foundation
import SwiftSyntax

/// Shorthand type forms must be used wherever possible.
///
/// Lint: Using a non-shorthand form (e.g. `Array<Element>`) yields a lint error unless the long
///       form is necessary (e.g. `Array<Element>.Index` cannot be shortened.)
///
/// Format: Where possible, shorthand types replace long form types; e.g. `Array<Element>` is
///         converted to `[Element]`.
///
/// - SeeAlso: https://google.github.io/swift#types-with-shorthand-names
public final class UseShorthandTypeNames: SyntaxFormatRule {

}
