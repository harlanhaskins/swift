// RUN: %empty-directory(%t/ModuleCache)

// Emit an interface that we can import.
// RUN: echo 'public func myFunc() {}' > %t/Test.swift

// RUN: %target-swift-frontend -typecheck %t/Test.swift -emit-module-interface-path %t/Test.swiftinterface -enable-library-evolution -sdk %S/Inputs/mock-sdk -module-name Test -swift-version 5

// First, import when all paths are absolute.
// RUN: %target-swift-frontend -typecheck %s -sdk %S/Inputs/mock-sdk -I %t -module-cache-path %t/ModuleCache

// These next invocations are invoking with the current directory set to either
// %S or %t, so that we make sure the paths are absolute when used in the module
// cache hash regardless of our working directory.
// RUN: ORIGINAL_DIR=$(pwd)

// Import when the SDK path is relative.
// RUN: cd %S
// RUN: %target-swift-frontend -typecheck %s -sdk Inputs/mock-sdk -I %t -module-cache-path %t/ModuleCache

// Import when there are a bunch of random dots in the path
// RUN: %target-swift-frontend -typecheck %s -sdk ./Inputs/../Inputs/./../Inputs/mock-sdk/./../mock-sdk/. -I %t -module-cache-path %t/ModuleCache

// Import when the interface path is relative.
// RUN: cd %t
// RUN: %target-swift-frontend -typecheck %s -sdk %S/Inputs/mock-sdk -I . -module-cache-path ModuleCache


// Make sure we only created one cached module.

// RUN: NUM_CACHED_MODULES=$(find %t/ModuleCache -type f -name 'Test-*.swiftmodule' | wc -l)
// RUN: if [ ! $NUM_CACHED_MODULES -eq 1 ]; then echo "Should only be 1 cached module, found $NUM_CACHED_MODULES"; exit 1; fi

// Restore the working dir
// RUN: cd $ORIGINAL_DIR

import Test
