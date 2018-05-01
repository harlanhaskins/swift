/// A Rule is a linting or formatting pass that executes in a given context.
public protocol Rule {
  /// The context in which the rule is executed.
  var context: Context { get }

  /// The human-readable name of the rule. This defaults to the class name.
  var ruleName: String { get }

  /// Creates a new Rule in a given context.
  init(context: Context)
}

private var nameCache = [ObjectIdentifier: String]()

extension Rule {
  /// By default, the `ruleName` is just the name of the implementing rule class.
  public var ruleName: String {
    let myType = type(of: self)
    // TODO(abl): Test and potentially replace with static initialization.
    return nameCache[
      ObjectIdentifier(myType),
      default: String("\(myType)".split(separator: ".").last!)
    ]
  }
}
