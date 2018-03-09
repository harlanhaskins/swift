import Foundation
import SwiftSyntax

extension Trivia {
  /// Returns this set of trivia, without any spaces.
  func withoutSpaces() -> Trivia {
    return Trivia(pieces: filter {
      if case .spaces = $0 { return false }
      if case .tabs = $0 { return true }
      return true
    })
  }

  /// Returns this set of trivia, without any newlines.
  func withoutNewlines() -> Trivia {
    return Trivia(pieces: filter {
      if case .newlines = $0 { return false }
      return true
    })
  }

  /// Returns this set of trivia, with all spaces removed except for one.
  func withOneSpace() -> Trivia {
    return withoutSpaces().appending(.spaces(1))
  }

  /// Returns this set of trivia, with all newlines removed except for one.
  func withOneNewline() -> Trivia {
    return .newlines(1) + withoutNewlines()
  }

  /// Returns `true` if this trivia contains any newlines.
  var containsNewlines: Bool {
    return contains(where: {
      if case .newlines = $0 { return true }
      return false
    })
  }

  /// Returns `true` if this trivia contains any spaces.
  var containsSpaces: Bool {
    return contains(where: {
      if case .spaces = $0 { return true }
      if case .tabs = $0 { return true }
      return false
    })
  }
}
