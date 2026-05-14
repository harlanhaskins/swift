// RUN: %empty-directory(%t)

// RUN: %target-swift-emit-silgen %s -module-name objcglobal > %t/out.sil
// RUN: %FileCheck %s -input-file %t/out.sil

// REQUIRES: objc_interop

import Foundation

// CHECK-LABEL: sil hidden [asmname "pear"] [ossa] @$s10objcglobal5appleyyS2iXCFTo : $@convention(c) (@convention(c) (Int) -> Int) -> () {
@objc(pear)
func apple(_ f: @convention(c) (Int) -> Int) { }

func acceptSwiftFunc(_ f: (Int) -> Int) { }

// CHECK-LABEL: sil hidden [ossa] @$s10objcglobal16forceCEntryPoint{{[_0-9a-zA-Z]*}}F
// CHECK: [[GRAPEFRUIT:%[0-9]+]] = function_ref @$s10objcglobal6orangeyS2iFTo : $@convention(c) (Int) -> Int
// CHECK: [[PEAR:%[0-9]+]] = function_ref @$s10objcglobal5appleyyS2iXCFTo : $@convention(c) (@convention(c) (Int) -> Int) -> ()
// CHECK: apply [[PEAR]]([[GRAPEFRUIT]])
func forceCEntryPoint() {
  apple(orange)
}

// CHECK-LABEL: sil hidden [asmname "grapefruit"] [ossa] @$s10objcglobal6orangeyS2iFTo : $@convention(c) (Int) -> Int {
@objc(grapefruit)
func orange(_ x: Int) -> Int {
  return x
}

// CHECK-LABEL: sil [asmname "cauliflower"] [ossa] @$s10objcglobal8broccoliyS2iFTo : $@convention(c) (Int) -> Int {
// CHECK-NOT: apply
// CHECK: return
@objc(cauliflower)
public func broccoli(_ x: Int) -> Int {
  return x
}

// CHECK-LABEL: sil hidden [asmname "defaultName"] [ossa] @$s10objcglobal11defaultNameyS2iFTo : $@convention(c) (Int) -> Int {
// CHECK-NOT: apply
// CHECK: return
@objc
func defaultName(_ x: Int) -> Int {
  return x
}

// CHECK-LABEL: sil hidden [asmname "nsObjectRoundTrip"] [ossa] @$s10objcglobal17nsObjectRoundTripySo8NSObjectCADFTo : $@convention(c) (NSObject) -> @autoreleased NSObject {
@objc(nsObjectRoundTrip)
func nsObjectRoundTrip(_ o: NSObject) -> NSObject {
  return o
}
