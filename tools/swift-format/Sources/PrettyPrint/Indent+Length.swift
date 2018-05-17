import Configuration

extension Indent {
  var character: Character {
    switch kind {
    case .tabs: return "\t"
    case .spaces: return " "
    }
  }

  var text: String {
    return String(repeating: character, count: count)
  }

  func length(in configuration: Configuration) -> Int {
    switch kind {
    case .spaces: return count
    case .tabs: return count * configuration.tabWidth
    }
  }
}

extension Array where Element == Indent {
  func indentation() -> String {
    return map { $0.text }.joined()
  }

  func length(in configuration: Configuration) -> Int {
    return reduce(into: 0) { $0 += $1.length(in: configuration) }
  }
}
