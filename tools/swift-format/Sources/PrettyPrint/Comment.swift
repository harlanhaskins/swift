struct Comment {
  enum Kind {
    case line, docLine, block, docBlock
  }
  let text: String

  func reflow(lineLength: Int) -> [Comment] {
    return []
  }
}
