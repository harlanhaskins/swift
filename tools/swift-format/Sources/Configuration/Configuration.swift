/// Holds the complete set of configured values and defaults.
public class Configuration: Codable {
  /// The version of the configuration; used in case of breaking changes in the future.
  public let version = 1

  /// MARK: Common configuration

  /// The maximum number of consecutive blank lines that may appear in a file.
  public var maximumBlankLines = 1

  /// The width of the horizontal tab in spaces.
  /// Used when converting indentation type.
  public var tabWidth = 8

  /// A string that represents a single level of indentation.
  /// All indentation will be conducted in multiples of this string.
  public let indentation = "  "

  /// MARK: Rule-specific configuration

  /// Rules for limiting blank lines between members.
  public let blankLineBetweenMembers = BlankLineBetweenMembersConfiguration()

  /// Rules for adding backticks around special symbols in documentation comments.
  public let surroundSymbolsWithBackticks = SurroundSymbolsWithBackticksConfiguration()

  /// Constructs a Configuration with all default values.
  public init() {}
}

/// Configuration for the BlankLineBetweenMembers rule.
public struct BlankLineBetweenMembersConfiguration: Codable {
  /// If true, blank lines are not required between single-line properties.
  public let ignoreSingleLineProperties = true
}

// TODO(abl): Expand the whitelist and blacklist.
/// Configuration for the SurroundSymbolsWithBackticks rule.
public struct SurroundSymbolsWithBackticksConfiguration: Codable {
  /// List of global symbols; added to the list of file-local symbols. Case-sensitive.
  public let symbolWhitelist = ["String"]

  /// List of symbols to ignore. Case-sensitive.
  public let symbolBlacklist = [
    "URL", // symbol name and capitalization is the same as the term.
  ]
}

/// Configuration for the NoPlaygroundLiterals rule.
public struct NoPlaygroundLiteralsConfiguration: Codable {
  public enum ResolveBehavior: String, Codable {
    /// If not sure, use `UIColor` to replace `#colorLiteral`.
    case useUIColor

    /// If not sure, use `NSColor` to replace `#colorLiteral`.
    case useNSColor

    /// If not sure, raise an error.
    case error
  }

  /// Resolution behavior to use when encountering an ambiguous `#colorLiteral`.
  public let resolveAmbiguousColor: ResolveBehavior = .useUIColor
}
