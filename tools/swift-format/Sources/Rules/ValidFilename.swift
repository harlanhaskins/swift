import Core
import Foundation

/// All Swift source files end with the extension `.swift` and are named based on contents.
/// If a file contains a single public type, it is named for that type.
/// If a file extends a type with protocol conformance, it is named `Type+Protocol`.
///
/// See: http://g3doc/company/teams/swift-readability/style_guide#file-names
///
/// Lint: If the above rules are violated, a lint error is raised.
public final class ValidFilename: FileRule {

}
