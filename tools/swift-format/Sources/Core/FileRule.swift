import Configuration
import SwiftSyntax

/// A linting rule that does not parse the file, but instead runs analyses over the raw text of
/// the file.
open class FileRule: Rule {
  /// The context in which this rule in run.
  public let context: Context

  /// Creates a new FileRule executing in the provided context.
  public required init(context: Context) {
    self.context = context
  }
}
