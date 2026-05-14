// RUN: %empty-directory(%t)
// RUN: split-file %s %t --leading-lines

// RUN: %target-swift-frontend(mock-sdk: %clang-importer-sdk) -typecheck \
// RUN:   -verify %t/main.swift -target %target-stable-abi-triple \
// RUN:   -import-bridging-header %t/Lib.h

// REQUIRES: objc_interop

//--- Lib.h
@import Foundation;

void ObjCImplFunc1(int param);
void ObjCImplFuncRenamed_C(int param)
    __attribute__((swift_name("ObjCImplFuncRenamed_Swift(arg:)")));

void ObjCImplFuncMismatch1(int param);

//--- main.swift
import Foundation

@implementation @objc
func ObjCImplFunc1(_: Int32) {}

@implementation @objc(ObjCImplFuncRenamed_C)
func ObjCImplFuncRenamed_Swift(arg: CInt) {}

@implementation @objc
func ObjCImplFuncMissing(_: Int32) {
  // expected-error@-2 {{could not find imported function 'ObjCImplFuncMissing' matching global function 'ObjCImplFuncMissing'; make sure you import the module or header that declares it}}
}

@implementation @objc
func ObjCImplFuncMismatch1(_: Float) {
  // expected-error@-1 {{global function 'ObjCImplFuncMismatch1' of type '(Float) -> ()' does not match type '(Int32) -> Void' declared by the header}}
}
