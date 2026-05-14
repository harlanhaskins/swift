/// Ensure '@objc' on a global function is printed into the Objective-C block
/// of the generated header.

// RUN: %empty-directory(%t)

// RUN: %target-swift-frontend(mock-sdk: %clang-importer-sdk) \
// RUN:   %s -emit-module -verify -o %t -emit-module-doc \
// RUN:   -emit-objc-header-path %t/objc.h \
// RUN:   -disable-objc-attr-requires-foundation-module

// RUN: %FileCheck %s --input-file %t/objc.h
// RUN: %check-in-clang %t/objc.h
// RUN: %check-in-clang-cxx %t/objc.h

// REQUIRES: objc_interop

import Foundation

// CHECK: SWIFT_EXTERN NSObject * _Nonnull objcDefaultWithValue(NSObject * _Nonnull value) SWIFT_NOEXCEPT
@objc
public func objcDefault(value: NSObject) -> NSObject { return value }

// CHECK: SWIFT_EXTERN NSObject * _Nonnull objcCustom(NSObject * _Nonnull value) SWIFT_NOEXCEPT
@objc(objcCustom)
public func objcWithCustomName(value: NSObject) -> NSObject { return value }
