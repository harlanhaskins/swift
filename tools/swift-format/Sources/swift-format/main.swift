//
//  main.swift
//  swift-format
//
//  Created by Dave Abrahams on 2/1/18.
//  Copyright © 2018 Dave Abrahams. All rights reserved.
//

import Foundation
import SwiftSyntax

struct X {
    func fubar() -> X { return self }
    var myself: X { return self }
}

extension Syntax {
    /// Walks to the root of the Syntax tree and computes a list of all ancestors
    /// of the receiver.
    var ancestors: [Syntax] {
        var nodes = [Syntax]()
        var current: Syntax = self
        while let parent = current.parent {
            nodes.append(current)
            current = parent
        }
        return nodes
    }

    var pathFromRoot: [Int] {
        var path = [Int]()
        var current: Syntax = self
        while let parent = current.parent {
            path.insert(current.indexInParent, at: 0)
            current = parent
        }
        return path
    }
}

func genericFunc<T : Collection, U: Collection>(x: T, y: U) -> (T.Element?, U.Element?)
where T.Index == U.Index, U.Iterator == IndexingIterator<[Int]> {
    _ = 3 * 4 + (5 * 6)
    _ = x.map { y->Int in 3 }
    _ = x.map { $0 }
    _ = X().fubar().fubar().fubar() // trailing comment
    _ = X().myself.myself
    _ = X().myself.fubar().myself.fubar()
    _ = X().fubar().myself.fubar().myself

    return (x.first, y.first)
}

func ascii16(_ x: UnicodeScalar) -> UTF16.CodeUnit {
    assert(x.isASCII)
    return UTF16.CodeUnit(x.value)
}

struct SourceLoc {
    var line = 0
    var column = 0

    mutating func traverse(_ text: String) {
        for c in text.utf16 {
            switch c {
            case 0xb, 0xc: line += 1// vertical linefeed, formfeed
            case ascii16("\n"): line += 1; column = 0
            case ascii16("\r"): column = 0
            default: column += 1
            }
        }
    }

    mutating func traverse(_ nonToken: TriviaPiece) {
        switch nonToken {
        case .spaces(let n), .tabs(let n), .backticks(let n):
            column += n

        case .verticalTabs(let n), .formfeeds(let n):
            line += n

        case .newlines(let n), .carriageReturnLineFeeds(let n):
            line += n
            column = 0

        case .carriageReturns(_):
            column = 0

        case .lineComment(let s),
            .blockComment(let s),
            .docLineComment(let s),
            .docBlockComment(let s),
            .garbageText(let s):

            traverse(s)
        }
    }

    mutating func traverseNonTrivia(_ token: TokenSyntax) {
        // DWA FIXME: this could be sped up by knowing the length of more tokens
        switch token.tokenKind {
        case .atSign,
            .colon,
            .semicolon,
            .comma,
            .period,
            .equal,
            .prefixPeriod,
            .leftParen,
            .rightParen,
            .leftBrace,
            .rightBrace,
            .leftSquareBracket,
            .rightSquareBracket,
            .leftAngle,
            .rightAngle,
            .prefixAmpersand,
            .postfixQuestionMark,
            .infixQuestionMark,
            .exclamationMark,
            .backslash,
            .stringQuote:
            column += 1
        case .arrow:
            column += 2
        default: traverse(token.text)
        }
    }
}

extension SourceLoc : CustomStringConvertible {
    var description: String {
        return "\(line + 1).\(column + 1)"
    }
}

extension SourceLoc : CustomDebugStringConvertible {
    var debugDescription: String {
        return "SourceLoc(line: \(line): column: \(column))"
    }
}

struct Node {
    init(_ x: Syntax) {
        syntax = x

        // For non-hashable nodes, fall back to mixing the path from that node
        // to the root of the tree as its identifier.
        if let hashableNode = x as? AnyHashable {
            id = hashableNode.hashValue
        } else {
            id = x.pathFromRoot.reduce(0) { $0 ^ _mixInt($1) }
        }
    }

    var kind: Syntax.Type {
        return type(of: syntax)
    }

    let syntax: Syntax
    let id: Int
}

extension Node : Equatable {
    static func == (x: Node, y: Node) -> Bool {
        return x.id == y.id
    }
}

extension BidirectionalCollection where Element : Equatable {
    func ends<S : BidirectionalCollection>(with s: S) -> Bool
    where S.Element == Self.Element
    {
        return self.reversed().starts(with: s.reversed())
    }

    func droppingSuffix<S : BidirectionalCollection>(_ s: S) -> SubSequence
    where S.Element == Self.Element
    {
        return self.ends(with: s) ? self.dropLast(s.count) : self[...]
    }
}

extension Node : CustomStringConvertible {
    var description: String {
        let syntaxCodeUnits = "Syntax".utf16
        let typeName = "\(kind)".utf16.split(separator: ".".utf16.first!).last!
        return String(typeName.droppingSuffix(syntaxCodeUnits))!
    }
}

extension TokenSyntax {
    /// True iff `self` might be mis-tokenized if placed next to an 'a' with no
    /// intervening whitespace.
    var isIdentifierLike: Bool {
        // DWA FIXME: This might be optimized by knowing more token kinds...
        if case .identifier(_) = tokenKind { return true }

        // ...but we should retain this fallback for resilience as the language
        // evolves.

        func isKnownIdentifierCodeUnit(_ c: UTF16.CodeUnit) -> Bool {
            switch c {
            case ascii16("_"),
                ascii16("a")...ascii16("z"),
                ascii16("A")...ascii16("Z"),
                ascii16("0")...ascii16("9"): return true
            default: return false
            }
        }

        let codeUnits = text.utf16

        if let first = codeUnits.first {
            if isKnownIdentifierCodeUnit(first) { return true }
        }
        if let last = codeUnits.last {
            if isKnownIdentifierCodeUnit(last) { return true }
        }
        return false
    }
}

struct Injection {
    var whitespaceRequired: Bool = false
    var newlineRequired: Bool = false
    var closeGroups: Int16 = 0
    var openGroups: Int16 = 0
}

enum OutputElement {
    case openGroup
    case closeGroup(matchingOpenIndex: Int)
    case whitespace
    case newline
    case token(syntax: TokenSyntax/*, location: SourceLoc*/)
}

typealias SyntaxID = Int

extension Syntax where Self : Hashable {
    var id: SyntaxID { return hashValue }
}

struct LazyDictionary<K : Hashable, V> {
    init(default: V) {
        defaultValue = { _ in `default` }
    }
    init(default: @escaping (K)->V) {
        defaultValue = `default`
    }

    subscript(key: K) -> V {
        get {
            return impl[key] ?? defaultValue(key)
        }
        set {
            impl[key] = newValue
        }
    }

    mutating func removeValue(forKey k: K) -> V? {
        return impl.removeValue(forKey: k)
    }

    var defaultValue: (K)->V
    var impl: [K : V] = [:]
}

final class Reparser : SyntaxVisitor {
    var content: [OutputElement] = []

    /// A stack of openGroup indices that have not yet been matched by a
    /// closeGroup.
    var unmatchedOpenGroups: [Int] = []

    var inputLocation = SourceLoc()
    var previousToken: TokenSyntax? = nil
    typealias Injections = LazyDictionary<SyntaxID, Injection>

    var before = Injections(default: Injection())
    var after = Injections(default: Injection())

    var nestingLevel = 0 // just used for debug output

    func openGroup() {
        unmatchedOpenGroups.append(content.count)
        content.append(.openGroup)
        nestingLevel += 1
    }

    func closeGroup() {
        nestingLevel -= 1
        content.append(
            .closeGroup(matchingOpenIndex: unmatchedOpenGroups.removeLast()))
    }

    func apply(_ a: inout Injections, to s: Node) {
        if let i = a.removeValue(forKey: s.id) {
            for _ in 0..<i.closeGroups { closeGroup() }

            if i.newlineRequired { content.append(.newline) }
            else if i.whitespaceRequired { content.append(.whitespace) }

            for _ in 0..<i.openGroups { openGroup() }
        }
    }

    func injectMandatoryNewlines(in statements: CodeBlockItemListSyntax) {
        for s in statements.dropLast() {
            if s.semicolon != nil { continue }
            after[s.id].newlineRequired = true
        }
    }

    override func visitPre(_ node: Syntax) {
        apply(&before, to: Node(node))
    }

    override func visitPost(_ node: Syntax) {
        apply(&after, to: Node(node))
    }

    override func visit(_ node: DeclNameArgumentsSyntax) {
        after[node.leftParen.id].openGroups += 1
        before[node.rightParen.id].closeGroups += 1
        super.visit(node)
    }

    override func visit(_ node: BinaryOperatorExprSyntax) {
        before[node.operatorToken.id].whitespaceRequired = true
        after[node.operatorToken.id].whitespaceRequired = true
        super.visit(node)
    }

    override func visit(_ node: TupleExprSyntax) {
        after[node.leftParen.id].openGroups += 1
        before[node.rightParen.id].closeGroups += 1
        super.visit(node)
    }

    override func visit(_ node: ArrayExprSyntax) {
        after[node.leftSquare.id].openGroups += 1
        before[node.rightSquare.id].closeGroups += 1
        super.visit(node)
    }

    override func visit(_ node: DictionaryExprSyntax) {
        after[node.leftSquare.id].openGroups += 1
        before[node.rightSquare.id].closeGroups += 1
        super.visit(node)
    }

    override func visit(_ node: ImplicitMemberExprSyntax) {
        before[node.id].whitespaceRequired = true
        super.visit(node)
    }

    override func visit(_ node: MemberAccessExprSyntax) {
        before[node.dot.id].openGroups += 1
        let closer: SyntaxID
        if let top = node.parent as? FunctionCallExprSyntax {
            closer = top.id
        } else {
            closer = node.id
        }
        after[closer].closeGroups += 1

        super.visit(node)
    }

    override func visit(_ node: ClosureCaptureSignatureSyntax) {
        after[node.leftSquare.id].openGroups += 1
        before[node.rightSquare.id].closeGroups += 1
        super.visit(node)
    }

    override func visit(_ node: ClosureExprSyntax) {
        injectMandatoryNewlines(in: node.statements)
        after[node.signature.map { $0.id } ?? node.leftBrace.id].openGroups += 1
        after[node.leftBrace.id].whitespaceRequired = true
        before[node.rightBrace.id].closeGroups += 1
        before[node.rightBrace.id].whitespaceRequired = true
        super.visit(node)
    }

    override func visit(_ node: FunctionCallExprSyntax) {
        if let l = node.leftParen, let r = node.rightParen {
            after[l.id].openGroups += 1
            before[r.id].closeGroups += 1
        }
        super.visit(node)
    }

    override func visit(_ node: SubscriptExprSyntax) {
        after[node.leftBracket.id].openGroups += 1
        before[node.rightBracket.id].closeGroups += 1
        super.visit(node)
    }

    override func visit(_ node: ExpressionSegmentSyntax) {
        after[node.leftParen.id].openGroups += 1
        before[node.rightParen.id].closeGroups += 1
        super.visit(node)
    }

    override func visit(_ node: ObjcKeyPathExprSyntax) {
        after[node.leftParen.id].openGroups += 1
        before[node.rightParen.id].closeGroups += 1
        super.visit(node)
    }

    override func visit(_ node: ObjectLiteralExprSyntax) {
        after[node.leftParen.id].openGroups += 1
        before[node.rightParen.id].closeGroups += 1
        super.visit(node)
    }

    override func visit(_ node: ParameterClauseSyntax) {
        after[node.leftParen.id].openGroups += 1
        before[node.rightParen.id].closeGroups += 1
        super.visit(node)
    }

    override func visit(_ node: ReturnClauseSyntax) {
        after[node.arrow.id].whitespaceRequired = true
        before[node.arrow.id].whitespaceRequired = true
        super.visit(node)
    }

    override func visit(_ node: ElseifDirectiveClauseSyntax) {
        injectMandatoryNewlines(in: node.body)
        super.visit(node)
    }

    override func visit(_ node: IfConfigDeclSyntax) {
        injectMandatoryNewlines(in: node.body)
        super.visit(node)
    }

    override func visit(_ node: MemberDeclBlockSyntax) {
        after[node.leftBrace.id].openGroups += 1
        after[node.leftBrace.id].whitespaceRequired = true
        before[node.leftBrace.id].whitespaceRequired = true
        before[node.rightBrace.id].closeGroups += 1
        before[node.rightBrace.id].whitespaceRequired = true
        super.visit(node)
    }

    override func visit(_ node: SourceFileSyntax) {
        injectMandatoryNewlines(in: node.items)
        super.visit(node)
    }

    override func visit(_ node: ElseDirectiveClauseSyntax) {
        injectMandatoryNewlines(in: node.body)
        super.visit(node)
    }

    override func visit(_ node: AccessLevelModifierSyntax) {
        if let l = node.openParen, let r = node.closeParen {
            after[l.id].openGroups += 1
            before[r.id].closeGroups += 1
        }
        super.visit(node)
    }

    override func visit(_ node: AccessorParameterSyntax) {
        after[node.leftParen.id].openGroups += 1
        before[node.rightParen.id].closeGroups += 1
        super.visit(node)
    }

    override func visit(_ node: AccessorBlockSyntax) {
        after[node.leftBrace.id].openGroups += 1
        after[node.leftBrace.id].whitespaceRequired = true
        before[node.rightBrace.id].closeGroups += 1
        before[node.rightBrace.id].whitespaceRequired = true
        super.visit(node)
    }

    override func visit(_ node: CodeBlockSyntax) {
        injectMandatoryNewlines(in: node.statements)
        after[node.openBrace.id].openGroups += 1
        after[node.openBrace.id].whitespaceRequired = true
        before[node.openBrace.id].whitespaceRequired = true
        before[node.closeBrace.id].closeGroups += 1
        before[node.closeBrace.id].whitespaceRequired = true
        super.visit(node)
    }

    override func visit(_ node: SwitchCaseSyntax) {
        injectMandatoryNewlines(in: node.body)
        super.visit(node)
    }

    override func visit(_ node: GenericParameterClauseSyntax) {
        after[node.leftAngleBracket.id].openGroups += 1
        before[node.rightAngleBracket.id].closeGroups += 1
        super.visit(node)
    }

    override func visit(_ node: ArrayTypeSyntax) {
        after[node.leftSquareBracket.id].openGroups += 1
        before[node.rightSquareBracket.id].closeGroups += 1
        super.visit(node)
    }

    override func visit(_ node: DictionaryTypeSyntax) {
        after[node.leftSquareBracket.id].openGroups += 1
        before[node.rightSquareBracket.id].closeGroups += 1
        super.visit(node)
    }

    override func visit(_ node: TupleTypeSyntax) {
        after[node.leftParen.id].openGroups += 1
        before[node.rightParen.id].closeGroups += 1
        super.visit(node)
    }

    override func visit(_ node: FunctionTypeSyntax) {
        after[node.leftParen.id].openGroups += 1
        before[node.rightParen.id].closeGroups += 1
        super.visit(node)
    }

    override func visit(_ node: GenericArgumentClauseSyntax) {
        after[node.leftAngleBracket.id].openGroups += 1
        before[node.rightAngleBracket.id].closeGroups += 1
        super.visit(node)
    }

    override func visit(_ node: TuplePatternSyntax) {
        after[node.openParen.id].openGroups += 1
        before[node.closeParen.id].closeGroups += 1
        super.visit(node)
    }

    override func visit(_ tok: TokenSyntax) {
        apply(&before, to: Node(tok))

        switch tok.tokenKind {
        case .rightParen, .rightBrace, .rightSquareBracket, .rightAngle:
            if tok.parent is UnknownStmtSyntax { closeGroup() }

        default: break
        }

        // Inject mandatory whitespace where we would otherwise create long
        // identifiers by jamming together things that should be separate.
        if let p = previousToken, p.isIdentifierLike, tok.isIdentifierLike {
            content.append(.whitespace)
        }

        for t in tok.leadingTrivia {
            inputLocation.traverse(t)
        }

        let tokenLocation = inputLocation
        inputLocation.traverseNonTrivia(tok)
#if false
        /// Dump tokens and syntax
        var endLocation = inputLocation
        if endLocation.column > 0 { endLocation.column -= 1 }
        print("""
            \(#file):\(tokenLocation)-\(endLocation):,\t\
            \(String(repeating: "    ", count: nestingLevel)) \
            '\(tok.text)' \t\t -> \(tok.ancestors)
            """
        )
#endif
        content.append(.token(syntax: tok))

        for t in tok.trailingTrivia {
            inputLocation.traverse(t)
        }

        switch tok.tokenKind {
        case .leftParen, .leftBrace, .leftSquareBracket, .leftAngle:
            if tok.parent is UnknownStmtSyntax { openGroup() }
        case .comma:
            content.append(.whitespace)
        default: break
        }

        apply(&after, to: Node(tok))
        previousToken = tok
    }
}

let p = Reparser()

// Parse a .swift file
let currentFile = URL(fileURLWithPath: #file)
do {
    // let currentFileContents = try String(contentsOf: currentFile)
    let parsed = try SourceFileSyntax.parse(currentFile)
    p.visit(parsed)
} catch ParserError.swiftcFailed(let n, let message) {
    print(message)
    exit(n == 0 ? 1 : Int32(n))
}
catch {
    print(error)
    exit(1)
}

let indentSpaces = 4
let columnLimit = 70

/// For each currently-open group, the indentation level of the line on which it
/// starts.
var groupIndentLevels = [0]
var lineBuffer = [OutputElement]()
var lineWidth = 0
/// The indentation at the beginning of this line
var bolIndentation = 0
/// The group nesting level at beginning of this line
var bolGrouping = groupIndentLevels.count
var whitespaceRequired = false
var lineUnmatchedIndices: [Int] = []

func outputLine() {
    var b = String(repeating: " ", count: bolIndentation * indentSpaces)
    var grouping = bolGrouping

    // flush through the first unmatched open grouping delimiter
    let flushCount = lineUnmatchedIndices.first.map { $0 + 1 } ?? lineBuffer.count
    for x in lineBuffer[..<flushCount] {
        switch x {
        case .openGroup:
            groupIndentLevels.append(bolIndentation)
            grouping += 1
            if grouping == bolGrouping { bolIndentation += 1 }
            // b += "〈"
        case .closeGroup:
            bolIndentation = groupIndentLevels.removeLast()
            grouping -= 1
            // b += "〉"
        case .whitespace:
            b += " "
        case .newline:
            break
        case .token(let t/*, _, _*/):
            b += t.text
        }
    }
    lineBuffer.removeFirst(flushCount)
    if !lineUnmatchedIndices.isEmpty {
        for i in 1..<lineUnmatchedIndices.count {
            lineUnmatchedIndices[i - 1] = lineUnmatchedIndices[i] - flushCount
        }
        lineUnmatchedIndices.removeLast()
    }

    print(b)
    if grouping > bolGrouping { bolIndentation += 1 }
    bolGrouping = grouping
    whitespaceRequired = false
    lineWidth = bolIndentation * indentSpaces
}

func flushLineBuffer() {
    while !lineBuffer.isEmpty { outputLine() }
}

for x in p.content {
    switch x {
    case .openGroup:
        lineUnmatchedIndices.append(lineBuffer.count)
        lineBuffer.append(x)
    case .closeGroup:
        lineBuffer.append(x)
        if !lineUnmatchedIndices.isEmpty {
            lineUnmatchedIndices.removeLast()
        }
        if groupIndentLevels.count == bolGrouping {
            flushLineBuffer()
        }
    case .whitespace:
        if !lineBuffer.isEmpty {
            whitespaceRequired = true
        }
    case .newline:
        flushLineBuffer()
    case .token(let t):
        let s = whitespaceRequired ? 1 : 0
        let w = t.text.count
        if lineWidth + s + w > columnLimit {
            outputLine()
        }
        else if whitespaceRequired {
            lineBuffer.append(.whitespace)
            lineWidth += 1
        }
        lineWidth += w
        lineBuffer.append(x)
        whitespaceRequired = false
   }
}
flushLineBuffer()
