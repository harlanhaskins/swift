import Core
import Foundation

/// Source files are encoded in UTF-8.
///
/// Lint: Files encoded in anything but UTF-8 will yield a lint error.
///
/// Format: If the given file is not UTF-8, it will be transcoded to UTF-8.
///
/// SeeAlso: https://google.github.io/swift#file-encoding
public final class UseOnlyUTF8: FileRule {

}
