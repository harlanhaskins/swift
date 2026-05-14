// RUN: %empty-directory(%t)
// RUN: split-file %s %t --leading-lines

/// Generate the compatibility header with the '@objc' global function declared.
// RUN: %target-swift-frontend(mock-sdk: %clang-importer-sdk) \
// RUN:   %t/Lib.swift -emit-module -verify -o %t -emit-module-doc \
// RUN:   -emit-objc-header-path %t/ObjCGlobal.h \
// RUN:   -disable-implicit-string-processing-module-import \
// RUN:   -disable-implicit-concurrency-module-import

/// Build and run a binary from Swift and Objective-C code.
// RUN: %clang-no-modules -c %t/Client.m -o %t/Client.o -target %target-triple \
// RUN:   %target-pic-opt -I %t -I %clang-include-dir -Werror -isysroot %sdk \
// RUN:   -fobjc-arc
// RUN: %target-build-swift %t/Lib.swift %t/Client.o -O -o %t/a.out \
// RUN:   -Xfrontend -disable-implicit-string-processing-module-import \
// RUN:   -Xfrontend -disable-implicit-concurrency-module-import \
// RUN:   -parse-as-library -framework Foundation
// RUN: %target-codesign %t/a.out
// RUN: %target-run %t/a.out > %t/run.log
// RUN: %FileCheck %s --input-file %t/run.log

// REQUIRES: executable_test
// REQUIRES: objc_interop

//--- Lib.swift

import Foundation

@objc(simple) public func simpleNameSwiftSide(x: CInt, bar y: CInt) -> CInt {
    print(x, y)
    return x
}

@objc public func defaultName(x: Int) {
    print(x)
}

@objc public func roundTripNSString(s: NSString) -> NSString {
    return "swift-\(s as String)" as NSString
}

//--- Client.m

#import <Foundation/Foundation.h>
#import "ObjCGlobal.h"

int main() {
    @autoreleasepool {
        int x = simple(42, 43);
        // CHECK: 42 43
        printf("%d\n", x);
        // CHECK-NEXT: 42

        defaultNameWithX(121);
        // CHECK-NEXT: 121

        NSString *s = roundTripNSStringWithS(@"hello");
        printf("%s\n", s.UTF8String);
        // CHECK-NEXT: swift-hello
    }
    return 0;
}
