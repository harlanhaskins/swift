import SwiftSyntax

struct SyntaxType: Hashable {
  let type: Syntax.Type

  static func ==(lhs: SyntaxType, rhs: SyntaxType) -> Bool {
    return ObjectIdentifier(lhs.type) == ObjectIdentifier(rhs.type)
  }

  var hashValue: Int {
    return ObjectIdentifier(type).hashValue
  }
}

/// Pipeline manages a mapping of linters and rewriters to the kinds of nodes they're supposed to
/// be run over.
public final class Pipeline: SyntaxRewriter {
  public enum Mode {
    case format, lint
  }
  let context: Context
  let mode: Mode

  /// Creates a Pipeline with the provided Context and Mode.
  ///
  /// - Parameters:
  ///   - context: The context in which to execute all of these passes.
  ///   - mode: The mode, `.format` or `.lint`, in which this pipeline should be run.
  public init(context: Context, mode: Mode) {
    self.context = context
    self.mode = mode
  }

  /// A list of file-based Syntax rules.
  private var fileRules = [FileRule]()

  // TODO(b/77533378): Respect priority of inserted Formatting passes. Should this be sorted on
  //                   insertion based on the priority of the pass type?

  /// A mapping between syntax types and closures that will perform rewriting operations over them.
  /// For lint-only passes, these closures will just return the same node unmodified -- that way
  /// we can maintain a standard interface for passes and share the same registry between format
  /// and lint mode.
  private var passMap = [SyntaxType: [(Syntax) -> Syntax]]()

  /// Adds a file-based rule to be run before format rules.
  ///
  /// - Parameter fileRule: The file-based lint rule metatype that will be run before any other
  ///                       formatting/lint rules.
  public func addFileRule(_ fileRule: FileRule.Type) {
    fileRules.append(fileRule.init(context: context))
  }

  /// Adds a given formatter to the registry of passes to run over nodes of the provided types.
  ///
  /// - Parameters
  ///   - formatType: The metatype of the formatter to be added, e.g. `ColonWhitespace.self`
  ///   - syntaxTypes: The list of syntax metatypes to apply format operations to.
  public func addFormatter(_ formatType: SyntaxFormatRule.Type, for syntaxTypes: Syntax.Type...) {
    for type in syntaxTypes {
      let formatter = formatType.init(context: context)
      passMap[SyntaxType(type: type), default: []].append(formatter.visit)
    }
  }

  /// Adds a given linter to the registry of passes, to be run over Syntax nodes of the provided
  /// types.
  ///
  /// - Parameters
  ///   - lintType: The metatype of the linter to be added, e.g. `AlwaysUseLowerCamelCase.self`
  ///   - syntaxTypes: The list of syntax metatypes to apply format operations to.
  public func addLinter(_ lintType: SyntaxLintRule.Type, for syntaxTypes: Syntax.Type...) {
    // If we're in format mode, don't add lint-only rules (they will be ignored).
    guard case .lint = mode else { return }

    for type in syntaxTypes {
      let linter = lintType.init(context: self.context)
      passMap[SyntaxType(type: type), default: []].append { node in
        linter.visit(node)
        return node
      }
    }
  }

  /// Keeps track of the current node we're visiting.
  ///
  /// When we recursively visit this node's children in order to apply passes to them, we need to be
  /// able to skip this visitAny(_:) call and actually perform the standard visit(_:) behavior. By
  /// keeping the current node saved, we can detect if we're recursing into visitAny(_:) and instead
  /// return `nil`.
  private var currentlyVisiting: Syntax?

  /// When a node is visited, first check to see if it has any formatting operations registered.
  ///
  /// If there are none registered for this node type, return `nil` to signify that the standard
  /// visitation behavior should occur.
  /// Otherwise, run our custon set of passes over the node and return the modified node.
  /// - Parameter node: The Syntax node to visit.
  /// - Returns: A transformed Syntax node, or `nil` if there haven't been any passes registered
  ///            for this type of node.
  public override func visitAny(_ node: Syntax) -> Syntax? {
    // if the node we're currently visiting is the node we've been passed, skip the pass lookup and
    // do a regular visit.
    if let current = currentlyVisiting, node == current {
      return nil
    }

    let syntaxType = SyntaxType(type: type(of: node))
    guard let passes = passMap[syntaxType] else { return nil }

    // Save the previously visited node. Once we're done, reset it to the node we visited before.
    let previouslyVisiting = currentlyVisiting
    currentlyVisiting = node
    defer { currentlyVisiting = previouslyVisiting }

    // Visit this node's children first
    let preVisited = visit(node)

    switch self.mode {
    case .format:
      // Perform all formatting passes on this node.
      return passes.reduce(preVisited) { accum, pass in
        pass(accum)
      }
    case .lint:
      // Perform all linting passes on this node.
      for pass in passes {
        _ = pass(preVisited)
      }
      return node
    }
  }
}
