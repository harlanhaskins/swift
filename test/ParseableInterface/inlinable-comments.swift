// RUN: %empty-directory(%t)
// RUN: %target-swift-frontend -emit-module -o %t/Test.swiftmodule -emit-parseable-module-interface-path %t/Test.swiftinterface -module-name Test %s
// RUN: %FileCheck %s < %t/Test.swiftinterface
// RUN: %target-swift-frontend -emit-module -o /dev/null -merge-modules %t/Test.swiftmodule -disable-objc-attr-requires-foundation-module -emit-parseable-module-interface-path - -module-name Test | %FileCheck %s

// CHECK: @inlinable public func hasComments() {
// CHECK-NOT: // line comment on its own line
// CHECK-NEXT: {{^}}  if true {{{$}}
// CHECK-NEXT: {{^}}    print ("Hello, world" ) {{$}}
// CHECK-NEXT: {{^}}  } {{$}}
// CHECK-NEXT: {{^}}}{{$}}
@inlinable public func hasComments() {
  // line comment on its own line
  /*test*/if true {// end line comment
    print/** doc comment
    */("Hello, world"/**/) /// doc line comment
  } // end line comment
}

// CHECK: @inlinable public func hasCommentsAndIfConfigs() {
// CHECK-NOT: #if true
// CHECK-NOT: // line comment on its own line
// CHECK-NEXT: {{^}}  if true {{{$}}
// CHECK-NEXT: {{^}}    print ("Hello, world" ) {{$}}
// CHECK-NEXT: {{^}}  } {{$}}
// CHECK-NOT: #endif
// CHECK-NEXT: {{^}}}{{$}}
@inlinable public func hasCommentsAndIfConfigs() {
  #if true
  // line comment on its own line
  /*test*/if true {// end line comment
    print/** doc comment
    */("Hello, world"/**/) /// doc line comment
  } // end line comment
  #endif
}