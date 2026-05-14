// RUN: %empty-directory(%t)

// RUN: %target-swift-frontend(mock-sdk: %clang-importer-sdk) \
// RUN:   -emit-module %s -o %t -I %t \
// RUN:   -swift-version 6 -enable-library-evolution \
// RUN:   -emit-module-interface-path %t/Lib.swiftinterface

// RUN: %target-swift-frontend(mock-sdk: %clang-importer-sdk) -I %t \
// RUN:   -typecheck-module-from-interface %t/Lib.swiftinterface

// RUN: %FileCheck %s --input-file %t/Lib.swiftinterface

// REQUIRES: objc_interop

import Foundation

@objc
public func bareObjC() {}
// CHECK: #if compiler(>=5.3) && hasAttribute(c)
// CHECK-NEXT: @objc public func bareObjC
// CHECK-NEXT: #else
// CHECK-NEXT: @_cdecl("bareObjC") public func bareObjC
// CHECK-NEXT: #endif

@objc(objc_name)
public func namedObjC() {}
// CHECK: #if compiler(>=5.3) && hasAttribute(c)
// CHECK-NEXT: @objc(objc_name) public func namedObjC
// CHECK-NEXT: #else
// CHECK-NEXT: @_cdecl("objc_name") public func namedObjC
// CHECK-NEXT: #endif
