public protocol Rule {
  var context: Context { get }
  var ruleName: String { get }
  init(context: Context)
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
