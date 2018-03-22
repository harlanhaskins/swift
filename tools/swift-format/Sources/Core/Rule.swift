public protocol Rule: Configurable {
  var ruleName: String { get }
}

private var nameCache = [ObjectIdentifier: String]()

extension Rule {
  public var ruleName: String {
    let myType = type(of: self)
    // TODO(abl): Test and potentially replace with static initialization.
    return nameCache[
      ObjectIdentifier(myType),
      default: String("\(myType)".split(separator: ".").last!)
    ]
  }
}
