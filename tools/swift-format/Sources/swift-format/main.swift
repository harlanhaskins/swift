//
//  main.swift
//  swift-format
//
//  Created by Dave Abrahams on 2/1/18.
//  Copyright © 2018 Dave Abrahams. All rights reserved.
//

import Foundation
import SwiftSyntax
import PrettyPrint

struct X {
    func fubar() -> X { return self }
    var myself: X { return self }
}

extension Syntax {
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

extension LazyDictionary where K == SyntaxID {
    subscript<T: Syntax & Hashable>(node: T) -> V {
        get {
            return self[node.id]
        }
        set {
            self[node.id] = newValue
        }
    }
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
            after[s].newlineRequired = true
        }
    }

    override func visitPre(_ node: Syntax) {
        apply(&before, to: Node(node))
    }

    override func visitPost(_ node: Syntax) {
        apply(&after, to: Node(node))
    }

    override func visit(_ node: DeclNameArgumentsSyntax) {
        after[node.leftParen].openGroups += 1
        before[node.rightParen].closeGroups += 1
        super.visit(node)
    }

    override func visit(_ node: BinaryOperatorExprSyntax) {
        before[node.operatorToken].whitespaceRequired = true
        after[node.operatorToken].whitespaceRequired = true
        super.visit(node)
    }

    override func visit(_ node: TupleExprSyntax) {
        after[node.leftParen].openGroups += 1
        before[node.rightParen].closeGroups += 1
        super.visit(node)
    }

    override func visit(_ node: ArrayExprSyntax) {
        after[node.leftSquare].openGroups += 1
        before[node.rightSquare].closeGroups += 1
        super.visit(node)
    }

    override func visit(_ node: DictionaryExprSyntax) {
        after[node.leftSquare].openGroups += 1
        before[node.rightSquare].closeGroups += 1
        super.visit(node)
    }

    override func visit(_ node: ImplicitMemberExprSyntax) {
        before[node].whitespaceRequired = true
        super.visit(node)
    }

    override func visit(_ node: FunctionParameterSyntax) {
        after[node.colon].whitespaceRequired = true
        super.visit(node)
    }

    override func visit(_ node: MemberAccessExprSyntax) {
        before[node.dot].openGroups += 1
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
        after[node.leftSquare].openGroups += 1
        before[node.rightSquare].closeGroups += 1
        super.visit(node)
    }

    override func visit(_ node: ClosureExprSyntax) {
        injectMandatoryNewlines(in: node.statements)
        after[node.signature.map { $0.id } ?? node.leftBrace.id].openGroups += 1
        after[node.leftBrace].whitespaceRequired = true
        before[node.rightBrace].closeGroups += 1
        before[node.rightBrace].whitespaceRequired = true
        after[node.rightBrace].newlineRequired = true
        super.visit(node)
    }

    override func visit(_ node: FunctionCallExprSyntax) {
        if let l = node.leftParen, let r = node.rightParen {
            after[l].openGroups += 1
            before[r].closeGroups += 1
        }
        super.visit(node)
    }

    override func visit(_ node: SubscriptExprSyntax) {
        after[node.leftBracket].openGroups += 1
        before[node.rightBracket].closeGroups += 1
        super.visit(node)
    }

    override func visit(_ node: ExpressionSegmentSyntax) {
        after[node.leftParen].openGroups += 1
        before[node.rightParen].closeGroups += 1
        super.visit(node)
    }

    override func visit(_ node: SwitchCaseLabelSyntax) {
        after[node.caseKeyword].whitespaceRequired = true
        after[node.colon].openGroups += 1
        after[node.colon].newlineRequired = true
        super.visit(node)
    }

    override func visit(_ node: SwitchDefaultLabelSyntax) {
        after[node.colon].newlineRequired = true
        super.visit(node)
    }

    override func visit(_ node: ObjcKeyPathExprSyntax) {
        after[node.leftParen].openGroups += 1
        before[node.rightParen].closeGroups += 1
        super.visit(node)
    }
    
    override func visit(_ node: AssignmentExprSyntax) {
        after[node.assignToken].whitespaceRequired = true
        before[node.assignToken].whitespaceRequired = true
        super.visit(node)
    }

    override func visit(_ node: ObjectLiteralExprSyntax) {
        after[node.leftParen].openGroups += 1
        before[node.rightParen].closeGroups += 1
        super.visit(node)
    }

    override func visit(_ node: ParameterClauseSyntax) {
        after[node.leftParen].openGroups += 1
        before[node.rightParen].closeGroups += 1
        super.visit(node)
    }

    override func visit(_ node: ReturnClauseSyntax) {
        after[node.arrow].whitespaceRequired = true
        before[node.arrow].whitespaceRequired = true
        super.visit(node)
    }

    override func visit(_ node: ElseifDirectiveClauseSyntax) {
        injectMandatoryNewlines(in: node.statements)
        super.visit(node)
    }

    override func visit(_ node: IfConfigDeclSyntax) {
        injectMandatoryNewlines(in: node.statements)
        super.visit(node)
    }

    override func visit(_ node: MemberDeclBlockSyntax) {
        after[node.leftBrace].openGroups += 1
        after[node.leftBrace].whitespaceRequired = true
        before[node.leftBrace].whitespaceRequired = true
        before[node.rightBrace].closeGroups += 1
        before[node.rightBrace].whitespaceRequired = true
        super.visit(node)
    }

    override func visit(_ node: SourceFileSyntax) {
        injectMandatoryNewlines(in: node.statements)
        super.visit(node)
    }

    override func visit(_ node: ElseDirectiveClauseSyntax) {
        injectMandatoryNewlines(in: node.statements)
        super.visit(node)
    }

    override func visit(_ node: AccessLevelModifierSyntax) {
        if let l = node.leftParen, let r = node.rightParen {
            after[l].openGroups += 1
            before[r].closeGroups += 1
        }
        super.visit(node)
    }

    override func visit(_ node: AccessorParameterSyntax) {
        after[node.leftParen].openGroups += 1
        before[node.rightParen].closeGroups += 1
        super.visit(node)
    }

    override func visit(_ node: AccessorBlockSyntax) {
        after[node.leftBrace].openGroups += 1
        after[node.leftBrace].whitespaceRequired = true
        before[node.rightBrace].closeGroups += 1
        before[node.rightBrace].whitespaceRequired = true
        super.visit(node)
    }

    override func visit(_ node: CodeBlockSyntax) {
        injectMandatoryNewlines(in: node.statements)
        after[node.leftBrace].openGroups += 1
        after[node.leftBrace].whitespaceRequired = true
        before[node.leftBrace].whitespaceRequired = true
        before[node.rightBrace].closeGroups += 1
        before[node.rightBrace].whitespaceRequired = true
        after[node.rightBrace].newlineRequired = true
        super.visit(node)
    }

    override func visit(_ node: SwitchCaseSyntax) {
        injectMandatoryNewlines(in: node.statements)
        super.visit(node)
    }

    override func visit(_ node: GenericParameterClauseSyntax) {
        after[node.leftAngleBracket].openGroups += 1
        before[node.rightAngleBracket].closeGroups += 1
        super.visit(node)
    }

    override func visit(_ node: ArrayTypeSyntax) {
        after[node.leftSquareBracket].openGroups += 1
        before[node.rightSquareBracket].closeGroups += 1
        super.visit(node)
    }

    override func visit(_ node: DictionaryTypeSyntax) {
        after[node.leftSquareBracket].openGroups += 1
        before[node.rightSquareBracket].closeGroups += 1
        super.visit(node)
    }

    override func visit(_ node: TupleTypeSyntax) {
        after[node.leftParen].openGroups += 1
        before[node.rightParen].closeGroups += 1
        super.visit(node)
    }

    override func visit(_ node: FunctionTypeSyntax) {
        after[node.leftParen].openGroups += 1
        before[node.rightParen].closeGroups += 1
        super.visit(node)
    }

    override func visit(_ node: GenericArgumentClauseSyntax) {
        after[node.leftAngleBracket].openGroups += 1
        before[node.rightAngleBracket].closeGroups += 1
        super.visit(node)
    }

    override func visit(_ node: TuplePatternSyntax) {
        after[node.leftParen].openGroups += 1
        before[node.rightParen].closeGroups += 1
        super.visit(node)
    }

    override func visit(_ node: AsExprSyntax) {
        super.visit(node)
    }

    override func visit(_ node: DoStmtSyntax) {
        super.visit(node)
    }

    override func visit(_ node: IfStmtSyntax) {
        super.visit(node)
    }

    override func visit(_ node: IsExprSyntax) {
        super.visit(node)
    }

    override func visit(_ node: TryExprSyntax) {
        super.visit(node)
    }

    override func visit(_ node: CaseItemSyntax) {
        super.visit(node)
    }

    override func visit(_ node: TypeExprSyntax) {
        super.visit(node)
    }

    override func visit(_ node: ArrowExprSyntax) {
        super.visit(node)
    }

    override func visit(_ node: AttributeSyntax) {
        super.visit(node)
    }

    override func visit(_ node: BreakStmtSyntax) {
        super.visit(node)
    }

    override func visit(_ node: ClassDeclSyntax) {
        super.visit(node)
    }

    override func visit(_ node: DeferStmtSyntax) {
        super.visit(node)
    }

    override func visit(_ node: ElseBlockSyntax) {
        super.visit(node)
    }

    override func visit(_ node: ForInStmtSyntax) {
        super.visit(node)
    }

    override func visit(_ node: GuardStmtSyntax) {
        super.visit(node)
    }

    override func visit(_ node: InOutExprSyntax) {
        super.visit(node)
    }

    override func visit(_ node: ThrowStmtSyntax) {
        super.visit(node)
    }

    override func visit(_ node: WhileStmtSyntax) {
        super.visit(node)
    }

    override func visit(_ node: ImportDeclSyntax) {
        super.visit(node)
    }

    override func visit(_ node: ReturnStmtSyntax) {
        super.visit(node)
    }

    override func visit(_ node: StructDeclSyntax) {
        super.visit(node)
    }

    override func visit(_ node: SwitchStmtSyntax) {
        super.visit(node)
    }

    override func visit(_ node: CatchClauseSyntax) {
        super.visit(node)
    }

    override func visit(_ node: DotSelfExprSyntax) {
        super.visit(node)
    }

    override func visit(_ node: KeyPathExprSyntax) {
        super.visit(node)
    }

    override func visit(_ node: TernaryExprSyntax) {
        super.visit(node)
    }

    override func visit(_ node: UnknownDeclSyntax) {
        super.visit(node)
    }

    override func visit(_ node: UnknownExprSyntax) {
        super.visit(node)
    }

    override func visit(_ node: UnknownStmtSyntax) {
        super.visit(node)
    }

    override func visit(_ node: UnknownTypeSyntax) {
        super.visit(node)
    }

    override func visit(_ node: WhereClauseSyntax) {
        super.visit(node)
    }

    override func visit(_ node: AccessorDeclSyntax) {
        super.visit(node)
    }

    override func visit(_ node: ArrayElementSyntax) {
        super.visit(node)
    }

    override func visit(_ node: ClosureParamSyntax) {
        super.visit(node)
    }

    override func visit(_ node: ContinueStmtSyntax) {
        super.visit(node)
    }

    override func visit(_ node: DeclModifierSyntax) {
        super.visit(node)
    }

    override func visit(_ node: FunctionDeclSyntax) {
        super.visit(node)
    }

    override func visit(_ node: MetatypeTypeSyntax) {
        super.visit(node)
    }

    override func visit(_ node: OptionalTypeSyntax) {
        super.visit(node)
    }

    override func visit(_ node: ProtocolDeclSyntax) {
        super.visit(node)
    }

    override func visit(_ node: SequenceExprSyntax) {
        super.visit(node)
    }

    override func visit(_ node: SuperRefExprSyntax) {
        super.visit(node)
    }

    override func visit(_ node: TupleElementSyntax) {
        super.visit(node)
    }

    override func visit(_ node: VariableDeclSyntax) {
        super.visit(node)
    }

    override func visit(_ node: AsTypePatternSyntax) {
        super.visit(node)
    }

    override func visit(_ node: CodeBlockItemSyntax) {
        super.visit(node)
    }

    override func visit(_ node: ExtensionDeclSyntax) {
        super.visit(node)
    }

    override func visit(_ node: InheritedTypeSyntax) {
        super.visit(node)
    }

    override func visit(_ node: IsTypePatternSyntax) {
        super.visit(node)
    }

    override func visit(_ node: ObjcNamePieceSyntax) {
        super.visit(node)
    }

    override func visit(_ node: PoundFileExprSyntax) {
        super.visit(node)
    }

    override func visit(_ node: PoundLineExprSyntax) {
        super.visit(node)
    }

    override func visit(_ node: StringSegmentSyntax) {
        super.visit(node)
    }

    override func visit(_ node: SubscriptDeclSyntax) {
        super.visit(node)
    }

    override func visit(_ node: TypealiasDeclSyntax) {
        super.visit(node)
    }

    override func visit(_ node: AttributedTypeSyntax) {
        super.visit(node)
    }

    override func visit(_ node: ExpressionStmtSyntax) {
        super.visit(node)
    }

    override func visit(_ node: IdentifierExprSyntax) {
        super.visit(node)
    }

    override func visit(_ node: NilLiteralExprSyntax) {
        super.visit(node)
    }

    override func visit(_ node: PatternBindingSyntax) {
        super.visit(node)
    }

    override func visit(_ node: PoundErrorDeclSyntax) {
        super.visit(node)
    }

    override func visit(_ node: SpecializeExprSyntax) {
        super.visit(node)
    }

    override func visit(_ node: TypeAnnotationSyntax) {
        super.visit(node)
    }

    override func visit(_ node: UnknownPatternSyntax) {
        super.visit(node)
    }

    override func visit(_ node: CompositionTypeSyntax) {
        super.visit(node)
    }

    override func visit(_ node: DeclarationStmtSyntax) {
        super.visit(node)
    }

    override func visit(_ node: EnumCasePatternSyntax) {
        super.visit(node)
    }

    override func visit(_ node: FallthroughStmtSyntax) {
        super.visit(node)
    }

    override func visit(_ node: ForcedValueExprSyntax) {
        super.visit(node)
    }

    override func visit(_ node: GenericArgumentSyntax) {
        super.visit(node)
    }

    override func visit(_ node: InitializerDeclSyntax) {
        super.visit(node)
    }

    override func visit(_ node: OptionalPatternSyntax) {
        super.visit(node)
    }

    override func visit(_ node: PoundColumnExprSyntax) {
        super.visit(node)
    }

    override func visit(_ node: RepeatWhileStmtSyntax) {
        super.visit(node)
    }

    override func visit(_ node: WildcardPatternSyntax) {
        super.visit(node)
    }

    override func visit(_ node: ClosureSignatureSyntax) {
        super.visit(node)
    }

    override func visit(_ node: ConditionElementSyntax) {
        super.visit(node)
    }

    override func visit(_ node: DeclNameArgumentSyntax) {
        super.visit(node)
    }

    override func visit(_ node: FloatLiteralExprSyntax) {
        super.visit(node)
    }

    override func visit(_ node: GenericParameterSyntax) {
        super.visit(node)
    }

    override func visit(_ node: PostfixUnaryExprSyntax) {
        super.visit(node)
    }

    override func visit(_ node: PoundWarningDeclSyntax) {
        super.visit(node)
    }

    override func visit(_ node: TupleTypeElementSyntax) {
        super.visit(node)
    }

    override func visit(_ node: DeinitializerDeclSyntax) {
        super.visit(node)
    }

    override func visit(_ node: DictionaryElementSyntax) {
        super.visit(node)
    }

    override func visit(_ node: ExpressionPatternSyntax) {
        super.visit(node)
    }

    override func visit(_ node: ValueBindingPatternSyntax) {
        super.visit(node)
    }

    override func visit(_ node: FunctionSignatureSyntax) {
        super.visit(node)
    }

    override func visit(_ node: IdentifierPatternSyntax) {
        super.visit(node)
    }

    override func visit(_ node: InitializerClauseSyntax) {
        super.visit(node)
    }

    override func visit(_ node: PoundFunctionExprSyntax) {
        super.visit(node)
    }

    override func visit(_ node: StringLiteralExprSyntax) {
        super.visit(node)
    }

    override func visit(_ node: AssociatedtypeDeclSyntax) {
        super.visit(node)
    }

    override func visit(_ node: BooleanLiteralExprSyntax) {
        super.visit(node)
    }

    override func visit(_ node: ClosureCaptureItemSyntax) {
        super.visit(node)
    }

    override func visit(_ node: ElseIfContinuationSyntax) {
        super.visit(node)
    }

    override func visit(_ node: GenericWhereClauseSyntax) {
        super.visit(node)
    }

    override func visit(_ node: IntegerLiteralExprSyntax) {
        super.visit(node)
    }

    override func visit(_ node: PoundDsohandleExprSyntax) {
        super.visit(node)
    }

    override func visit(_ node: PrefixOperatorExprSyntax) {
        super.visit(node)
    }

    override func visit(_ node: AccessPathComponentSyntax) {
        super.visit(node)
    }

    override func visit(_ node: SameTypeRequirementSyntax) {
        super.visit(node)
    }

    override func visit(_ node: TuplePatternElementSyntax) {
        super.visit(node)
    }

    override func visit(_ node: FunctionCallArgumentSyntax) {
        super.visit(node)
    }

    override func visit(_ node: MemberTypeIdentifierSyntax) {
        super.visit(node)
    }

    override func visit(_ node: OptionalChainingExprSyntax) {
        super.visit(node)
    }

    override func visit(_ node: SimpleTypeIdentifierSyntax) {
        super.visit(node)
    }

    override func visit(_ node: AvailabilityConditionSyntax) {
        super.visit(node)
    }

    override func visit(_ node: DiscardAssignmentExprSyntax) {
        super.visit(node)
    }

    override func visit(_ node: EditorPlaceholderExprSyntax) {
        super.visit(node)
    }

    override func visit(_ node: SymbolicReferenceExprSyntax) {
        super.visit(node)
    }

    override func visit(_ node: TypeInheritanceClauseSyntax) {
        super.visit(node)
    }

    override func visit(_ node: TypeInitializerClauseSyntax) {
        super.visit(node)
    }

    override func visit(_ node: UnresolvedPatternExprSyntax) {
        super.visit(node)
    }

    override func visit(_ node: CompositionTypeElementSyntax) {
        super.visit(node)
    }

    override func visit(_ node: ConformanceRequirementSyntax) {
        super.visit(node)
    }

    override func visit(_ node: StringInterpolationExprSyntax) {
        super.visit(node)
    }

    override func visit(_ node: MatchingPatternConditionSyntax) {
        super.visit(node)
    }

    override func visit(_ node: OptionalBindingConditionSyntax) {
        super.visit(node)
    }

    override func visit(_ node: ImplicitlyUnwrappedOptionalTypeSyntax) {
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
            '\(tok.text)'
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

func main() {
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

    let indentSpaces = 2
    let columnLimit = 80

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
}


try prettyPrint(tokens: [
    .string("func foo("),
    .begin(offset: 2, breakType: .consistent),
    .break(blankSpace: 0, offset: 0),
    .string("_ foo : Int"),
    .break(blankSpace: 1, offset: 0),
    .end,
    .string(") -> Int {"),
    .begin(offset: 2, breakType: .consistent),
    .break(blankSpace: 1, offset: 0),
    .string("return 3"),
    .break(blankSpace: 1, offset: 0),
    .end,
    .string("}"),
    .string("func foo("),
    .begin(offset: 2, breakType: .consistent),
    .break(blankSpace: 0, offset: 0),
    .string("_ foo : Int"),
    .break(blankSpace: 1, offset: 0),
    .end,
    .string(") -> Int {"),
    .begin(offset: 2, breakType: .consistent),
    .break(blankSpace: 1, offset: 0),
    .string("return 3"),
    .break(blankSpace: 1, offset: 0),
    .end,
    .string("}"),
    .string("func foo("),
    .begin(offset: 2, breakType: .consistent),
    .break(blankSpace: 0, offset: 0),
    .string("_ foo : Int"),
    .break(blankSpace: 1, offset: 0),
    .end,
    .string(") -> Int {"),
    .begin(offset: 2, breakType: .consistent),
    .break(blankSpace: 1, offset: 0),
    .string("return 3"),
    .break(blankSpace: 1, offset: 0),
    .end,
    .string("}"),
    .string("func foo("),
    .begin(offset: 2, breakType: .consistent),
    .break(blankSpace: 0, offset: 0),
    .string("_ foo : Int"),
    .break(blankSpace: 1, offset: 0),
    .end,
    .string(") -> Int {"),
    .begin(offset: 2, breakType: .consistent),
    .break(blankSpace: 1, offset: 0),
    .string("return 3"),
    .break(blankSpace: 1, offset: 0),
    .end,
    .string("}"),
    .string("func foo("),
    .begin(offset: 2, breakType: .consistent),
    .break(blankSpace: 0, offset: 0),
    .string("_ foo : Int"),
    .break(blankSpace: 1, offset: 0),
    .end,
    .string(") -> Int {"),
    .begin(offset: 2, breakType: .consistent),
    .break(blankSpace: 1, offset: 0),
    .string("return 3"),
    .break(blankSpace: 1, offset: 0),
    .end,
    .string("}"),
    .string("func foo("),
    .begin(offset: 2, breakType: .consistent),
    .break(blankSpace: 0, offset: 0),
    .string("_ foo : Int"),
    .break(blankSpace: 1, offset: 0),
    .end,
    .string(") -> Int {"),
    .begin(offset: 2, breakType: .consistent),
    .break(blankSpace: 1, offset: 0),
    .string("return 3"),
    .break(blankSpace: 1, offset: 0),
    .end,
    .string("}"),
    .eof
])
print()
