import Foundation
import SwiftSyntax

extension Trivia {
  /// Returns this set of trivia, without any spaces.
  func withoutSpaces() -> Trivia {
    return Trivia(pieces: filter {
      if case .spaces = $0 { return false }
      return true
    })
  }

  /// Returns this set of trivia, with all spaces removed except for one.
  func withOneSpace() -> Trivia {
    return withoutSpaces().appending(.spaces(1))
  }
}
