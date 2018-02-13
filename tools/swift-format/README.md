# swift-format

Swift-format is a standardized Swift formatting tool similar to clang-format.
It is currently in a molten state, and includes a pretty printer based on D.C.
Oppen's 1980 [research paper](https://dl.acm.org/citation.cfm?id=357115).

Swift-format uses
[libSyntax](https://github.com/apple/swift/tree/master/lib/Syntax) to read the
Swift Syntax tree and generate a token stream that can be consumed by the
pretty printer.
