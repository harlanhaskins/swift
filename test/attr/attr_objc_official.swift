/// @objc on a global function.

// RUN: %target-swift-frontend(mock-sdk: %clang-importer-sdk) -typecheck -verify %s

// REQUIRES: objc_interop

import Foundation

#if hasAttribute(c)
// good
#else
#error("missing the attribute feature we're using")
#endif

@objc(objc_foo) func foo(x: Int) -> Int { return x }

@objc func defaultName() {}

@objc(foo:bar:) // expected-error {{'@objc' global function must have a simple name}}
func selectorNameGlobal(foo: Int, bar: Int) {}

@objc(`inout`)
func objcInout(x: inout Int) { } // expected-error{{global function cannot be marked '@objc' because inout parameters cannot be represented in Objective-C}}

struct SwiftStruct { var x, y: Int }
enum SwiftEnum { case A, B }

@objc class ObjCClass: NSObject { }

@objc(classParam)
func classParam(p: ObjCClass) {}

@objc(nsObjectParam)
func nsObjectParam(p: NSObject) -> NSObject { return p }

@objc(swiftStruct)
func objcSwiftStruct(x: SwiftStruct) {}
// expected-error @-1 {{global function cannot be marked '@objc' because the type of the parameter cannot be represented in Objective-C}}
// expected-note @-2 {{Swift structs cannot be represented in Objective-C}}

@objc(swiftEnum)
func objcSwiftEnum(x: SwiftEnum) {}
// expected-error @-1 {{global function cannot be marked '@objc' because the type of the parameter cannot be represented in Objective-C}}
// expected-note @-2 {{Swift enums not marked '@c' or '@objc' cannot be represented in Objective-C}}

@objc(throwing) // expected-error{{raising errors from @objc functions is not supported}}
func objcThrowing() throws { }

@objc(generic)
func objcGeneric<T>(value: T) {}
// expected-error @-1 {{global function cannot be marked '@objc' because it has generic parameters}}

@c(CDeclAndObjC) // expected-error {{cannot apply both '@c' and '@objc'}}
@objc(objcDeclAndC)
func cDeclAndObjC(x: CInt) -> CInt { return x }

class Foo {
  @c(Foo_foo) // expected-error{{@c can only be applied to global functions}}
  func foo(x: Int) -> Int { return x }
}
