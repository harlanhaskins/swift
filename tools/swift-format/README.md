# swift-format

## Summary

`swift-format` reformats Swift files to help them conform to the
[Google Swift Style Guide](https://google.github.io/swift). Alternatively, it can be used
as a linter.

## Rules

All rules subclass `Rule` and conform to one or more protocols.

`Rule`s may be enabled or disabled via configuration; some rules provide
additional configuration options.

All rules must be implemeneted in `Sources/Rules` as a single file with a type
matching the name of the file; e.g. `ValidFilename.swift` contains
`public final class ValidFilename`.

### Formatting Invariants

There are certain invariants that all rules may safely assume:

1. All leftBrace-like characters (e.g. `{`, `(`, `[`, `<`) add one level of
   indentation to all subsequent lines.
2. All rightBrace-like characters (e.g. `}`, `)`, `]`, `>`) remove one level of
   indentation from all subsequent lines.
3. Lines beginning with a rightBrace-like character remove one level of
   indentation *from their line*.
4. The `where` keyword adds a level of indentation to its clause iff the clause
   is multi-line.
5. The `{` which terminates a `where` clause occurs on a new line at the same
   level of indentation as the `where` clause.

some examples, assuming two-space indentation:

```swift
public func indexA<Elements: Collection, Element>(
  of element: Element,
  in collection: Elements
) -> Elements.Index?
where
  Elements.Element == Element, // note indentation
  Element: Equatable
{
  for current in elements {
    print(
      "Current element: \(current)"
    )
    print(
      "Current element: \(current)") // note that indentation is not changed
    print("Current element: \(current)")
  }
}

public func indexB<Elements: Collection, Element>(
  of element: Element,
  in collection: Elements
) -> Elements.Index?
where Elements.Element == Element, Element: Equatable {
  for current in elements {
    print(
      "Current element: \(current)"
    )
    print(
      "Current element: \(current)") // note that indentation is not changed
    print("Current element: \(current)")
  }
}
```

These invariants simplify the creation of formatting rules that might create new
lines.

### Interaction

#### Linting

Lint rules **must not** conflict. If two rules have an unavoidable conflict,
they **must** be refactored into a single rule.

#### Formatting

Format rules **must not** introduce lint errors in **any** rule. The only
exception to this is line length; it is assumed that the final printing pass
will handle line length format concerns.

Format rules **may** conflict. If two rules conflict, they **must** be given
priority ordering such that:

1. The transformation is determinstic and sensible; at the end of each rule's
   changes, the tree should be in a reasonable state. (Remember that rules can
   and will be disabled, and tested, individually.)
2. Running `swift-format` a second time does not result in any changes.

#### Notes

When considering conflicts and ordering, it is assumed that *all* rules in the
project are executed using default configuration. The goal of this project is to
produce well-formatted Swift code in compliance with the style guide; doing so
requires all formatters to be enabled.

### Naming

`Rule`s should have a clear name indicating what is being enforced; it is not
necessary to include `Rule`, `FormatRule`, or `LintRule` in the name of the
type.

The name of the `Rule` is present in linting output; it should be immediately
obvious what check was failed.

```swift
// Bad examples, redundant nouns
class ValidFilenameLintRule {}
class UTF8Rule {}
class WhitespaceFormatRule {}

// Better, but not ideal
class FilenameValidator {} // Describes what the class does, not the check
class CheckForUTF8 {} // Doesn't make sense as a formatter; "Check" is redundant
class AllWhitespacesAreRegularSpaces {} // Too long

// Best
class ValidFilename {}
class UseOnlyUTF8 {}
class UseOnlySpaces {}
```

This leads to error messages like the following:

```
ValidFilename:0:0:"MyInvalidFilename.c" does not end with ".swift"
UseOnlyUTF8:0:0:UTF-16 detected
UseOnlySpaces:20:0:Tab character detected
```

The information on the left-hand side (class name) lets the right-hand side be
brief and to the point.

### Protocols

#### LintRule

This rule can be run as a linter; linters are expected to raise warnings and/or
errors about specific faults on specific lines+columns.

When possible, linters should provide a corrective action, e.g.:

```
# Bad example
LintedFile.swift:0:0:Not all string literals use special characters correctly.

# Better, but not great
LintedFile.swift:20:0:Inappropriate escapes in string literal.

# Best example
LintedFile.swift:20:40:Replace "\u{000a}" with "\n" in this string literal.

```

#### FormatRule

This rule can be run as a formatter; formatters are a subset of linters which
can automatically correct errors.

If a rule is a FormatRule it **must** be able to resolve **all** matching
LintRule errors; if it can only fix a subset of errors the rule should be
divided into two or more rules.

#### Priority

This rule has a `priority: Int`; rules with a higher priority are executed
first.

Rules that do not conform to this protocol are assumed to have `priority == 0`.
Priorities less than 0 are OK.

### Classes

#### FileRule

This rule operates at a file level; for example, `ValidFilename` checks to see
if the given file has a valid filename. `UseOnlySpaces` reads file contents to
look for any forbidden whitespace characters.

#### SyntaxBasedFormatRule

This rule operates at a syntax level; for example, `ValidStringLiterals` uses
`SwiftSyntax` to examine the contents of every string literal in the given file.

This class extends `SyntaxRewriter`.

#### SyntaxLintRule

Same as `SyntaxFormatRule` but extends `SyntaxVisitor`.

### Documentation

All rules must have documentation conforming to this form. Separate each section
using a single empty line.

```swift
/// <REQUIRED: one sentence description of the rule that fits on a single line.>
///
/// <OPTIONAL: a longer description of the rule.>
///
/// Lint: <REQUIRED: a description of what is linted. Separate different types
///       of lint using a line break e.g.:>
///       <OPTIONAL: the second thing being linted if appropriate>
///
/// Format: <OPTIONAL: If the rule is a formatter, describe the formatting here.
///         Use the same rules as the Lint: section.>
///
/// Configuration: <OPTIONAL: If there is any configuration, specify which variables can be
///                configured>
///
/// - SeeAlso: <REQUIRED: a link to the relevant section of the style guide.>
///            <OPTIONAL: another link to the style guide.>
```

Here's an example:

```swift
/// Enforces restrictions on unicode escape sequences/characters in string literals.
///
/// String literals will not mix unicode escape sequences with non-ASCII characters, and will
/// not consist of a single un-escaped Unicode control character, combining character, or variant
/// selector.
///
/// Lint: If a string consists of only Unicode control characters, combining characters, or variant
///       selectors, a lint error is raised.
///       If a string mixes non-ASCII characters and Unicode escape sequences, a lint error is
///       raised.
/// Format: String literals consisting of only Unicode modifiers will be replaced with the
///         equivalent unicode escape sequences.
///         String literals which mix non-ASCII characters and Unicode escape sequences will have
///         their unicode escape sequences replaced with the corresponding Unicode character.
///
/// - SeeAlso: https://google.github.io/swift#invisible-characters-and-modifiers
///            https://google.github.io/swift#string-literals
```

### Configuration

A single instance of `Configuration` is provided to every invoked rule; this
instance captures both common values (e.g. `maximumBlankLines`) and
rule-specific `struct`s that contain any number of rule-specific values.

Rules **must not** depend on the configuration of other rules; that
configuration should be moved to the common set if necessary.

Rules *should not* duplicate similar configuration values; for example,
`maximumBlankLines` applies to `MaximumBlankLines` and `BlankLineBetweenMembers`
as it has the same application.

## Pretty Printer

The (not yet implemented) pretty printer is responsible for consuming a
formatted syntax tree and emitting an indentation-aware, line-length-aware,
corrected source file.
