
// RUN: %empty-directory(%t)
// RUN: %build-silgen-test-overlays

// RUN: %target-swift-emit-silgen(mock-sdk: -sdk %S/Inputs -I %t) -module-name dynamic -Xllvm -sil-full-demangle -primary-file %s %S/Inputs/dynamic_other.swift | %FileCheck %s
// RUN: %target-swift-emit-sil(mock-sdk: -sdk %S/Inputs -I %t) -module-name dynamic -Xllvm -sil-full-demangle -primary-file %s %S/Inputs/dynamic_other.swift -verify

// REQUIRES: objc_interop

import Foundation
import gizmo

class Foo: Proto {
  // Not objc or dynamic, so only a vtable entry
  init(native: Int) {}
  func nativeMethod() {}
  var nativeProp: Int = 0
  subscript(native native: Int) -> Int {
    get { return native }
    set {}
  }

  // @objc, so it has an ObjC entry point but can also be dispatched
  // by vtable
  @objc init(objc: Int) {}
  @objc func objcMethod() {}
  @objc var objcProp: Int = 0
  @objc subscript(objc objc: AnyObject) -> Int {
    get { return 0 }
    set {}
  }

  // dynamic, so it has only an ObjC entry point
  @objc dynamic init(dynamic: Int) {}
  @objc dynamic func dynamicMethod() {}
  @objc dynamic var dynamicProp: Int = 0
  @objc dynamic subscript(dynamic dynamic: Int) -> Int {
    get { return dynamic }
    set {}
  }

  func overriddenByDynamic() {}

  @NSManaged var managedProp: Int
}

protocol Proto {
  func nativeMethod()
  var nativeProp: Int { get set }
  subscript(native native: Int) -> Int { get set }

  func objcMethod()
  var objcProp: Int { get set }
  subscript(objc objc: AnyObject) -> Int { get set }

  func dynamicMethod()
  var dynamicProp: Int { get set }
  subscript(dynamic dynamic: Int) -> Int { get set }
}

// ObjC entry points for @objc and dynamic entry points

// normal and @objc initializing ctors can be statically dispatched
// CHECK-LABEL: sil hidden @$s7dynamic3FooC{{.*}}tcfC
// CHECK:         function_ref @$s7dynamic3FooC{{.*}}tcfc

// CHECK-LABEL: sil hidden @$s7dynamic3FooC{{.*}}tcfC
// CHECK:         function_ref @$s7dynamic3FooC{{.*}}tcfc

// CHECK-LABEL: sil hidden [thunk] @$s7dynamic3{{[_0-9a-zA-Z]*}}fcTo
// CHECK-LABEL: sil hidden [thunk] @$s7dynamic3FooC10objcMethod{{[_0-9a-zA-Z]*}}FTo
// CHECK-LABEL: sil hidden [transparent] [thunk] @$s7dynamic3FooC8objcPropSivgTo
// CHECK-LABEL: sil hidden [transparent] [thunk] @$s7dynamic3FooC8objcPropSivsTo
// CHECK-LABEL: sil hidden [thunk] @$s7dynamic3FooC4objcSiyXl_tcigTo
// CHECK-LABEL: sil hidden [thunk] @$s7dynamic3FooC4objcSiyXl_tcisTo

// TODO: dynamic initializing ctor must be objc dispatched
// CHECK-LABEL: sil hidden @$s7dynamic3{{[_0-9a-zA-Z]*}}fC
// CHECK:         function_ref @$s7dynamic3{{[_0-9a-zA-Z]*}}fcTD
// CHECK-LABEL: sil shared [transparent] [serializable] [thunk] @$s7dynamic3{{[_0-9a-zA-Z]*}}fcTD
// CHECK:         objc_method {{%.*}} : $Foo, #Foo.init!initializer.uncurried.foreign :

// CHECK-LABEL: sil hidden [thunk] @$s7dynamic3{{[_0-9a-zA-Z]*}}fcTo
// CHECK-LABEL: sil hidden [thunk] @$s7dynamic3FooC0A6Method{{[_0-9a-zA-Z]*}}FTo
// CHECK-LABEL: sil hidden [transparent] [thunk] @$s7dynamic3FooC0A4PropSivgTo
// CHECK-LABEL: sil hidden [transparent] [thunk] @$s7dynamic3FooC0A4PropSivsTo
// CHECK-LABEL: sil hidden [thunk] @$s7dynamic3FooCAAS2i_tcigTo
// CHECK-LABEL: sil hidden [thunk] @$s7dynamic3FooCAAS2i_tcisTo

// Protocol witnesses use best appropriate dispatch

// Native witnesses use vtable dispatch:
// CHECK-LABEL: sil private [transparent] [thunk] @$s7dynamic3FooCAA5ProtoA2aDP12nativeMethod{{[_0-9a-zA-Z]*}}FTW
// CHECK:         class_method {{%.*}} : $Foo, #Foo.nativeMethod.uncurried :
// CHECK-LABEL: sil private [transparent] [thunk] @$s7dynamic3FooCAA5ProtoA2aDP10nativePropSivgTW
// CHECK:         class_method {{%.*}} : $Foo, #Foo.nativeProp!getter.uncurried :
// CHECK-LABEL: sil private [transparent] [thunk] @$s7dynamic3FooCAA5ProtoA2aDP10nativePropSivsTW
// CHECK:         class_method {{%.*}} : $Foo, #Foo.nativeProp!setter.uncurried :
// CHECK-LABEL: sil private [transparent] [thunk] @$s7dynamic3FooCAA5ProtoA2aDP6nativeS2i_tcigTW
// CHECK:         class_method {{%.*}} : $Foo, #Foo.subscript!getter.uncurried :
// CHECK-LABEL: sil private [transparent] [thunk] @$s7dynamic3FooCAA5ProtoA2aDP6nativeS2i_tcisTW
// CHECK:         class_method {{%.*}} : $Foo, #Foo.subscript!setter.uncurried :

// @objc witnesses use vtable dispatch:
// CHECK-LABEL: sil private [transparent] [thunk] @$s7dynamic3FooCAA5ProtoA2aDP10objcMethod{{[_0-9a-zA-Z]*}}FTW
// CHECK:         class_method {{%.*}} : $Foo, #Foo.objcMethod.uncurried :
// CHECK-LABEL: sil private [transparent] [thunk] @$s7dynamic3FooCAA5ProtoA2aDP8objcPropSivgTW
// CHECK:         class_method {{%.*}} : $Foo, #Foo.objcProp!getter.uncurried :
// CHECK-LABEL: sil private [transparent] [thunk] @$s7dynamic3FooCAA5ProtoA2aDP8objcPropSivsTW
// CHECK:         class_method {{%.*}} : $Foo, #Foo.objcProp!setter.uncurried :
// CHECK-LABEL: sil private [transparent] [thunk] @$s7dynamic3FooCAA5ProtoA2aDP4objcSiyXl_tcigTW
// CHECK:         class_method {{%.*}} : $Foo, #Foo.subscript!getter.uncurried :
// CHECK-LABEL: sil private [transparent] [thunk] @$s7dynamic3FooCAA5ProtoA2aDP4objcSiyXl_tcisTW
// CHECK:         class_method {{%.*}} : $Foo, #Foo.subscript!setter.uncurried :

// Dynamic witnesses use objc dispatch:
// CHECK-LABEL: sil private [transparent] [thunk] @$s7dynamic3FooCAA5ProtoA2aDP0A6Method{{[_0-9a-zA-Z]*}}FTW
// CHECK:         function_ref @$s7dynamic3FooC0A6Method{{[_0-9a-zA-Z]*}}FTD
// CHECK-LABEL: sil shared [transparent] [serializable] [thunk] @$s7dynamic3FooC0A6Method{{[_0-9a-zA-Z]*}}FTD
// CHECK:         objc_method {{%.*}} : $Foo, #Foo.dynamicMethod.uncurried.foreign :

// CHECK-LABEL: sil private [transparent] [thunk] @$s7dynamic3FooCAA5ProtoA2aDP0A4PropSivgTW
// CHECK:         function_ref @$s7dynamic3FooC0A4PropSivgTD
// CHECK-LABEL: sil shared [transparent] [serializable] [thunk] @$s7dynamic3FooC0A4PropSivgTD
// CHECK:         objc_method {{%.*}} : $Foo, #Foo.dynamicProp!getter.uncurried.foreign :

// CHECK-LABEL: sil private [transparent] [thunk] @$s7dynamic3FooCAA5ProtoA2aDP0A4PropSivsTW
// CHECK:         function_ref @$s7dynamic3FooC0A4PropSivsTD
// CHECK-LABEL: sil shared [transparent] [serializable] [thunk] @$s7dynamic3FooC0A4PropSivsTD
// CHECK:         objc_method {{%.*}} : $Foo, #Foo.dynamicProp!setter.uncurried.foreign :

// CHECK-LABEL: sil private [transparent] [thunk] @$s7dynamic3FooCAA5ProtoA2aDPAAS2i_tcigTW
// CHECK:         function_ref @$s7dynamic3FooCAAS2i_tcigTD
// CHECK-LABEL: sil shared [transparent] [serializable] [thunk] @$s7dynamic3FooCAAS2i_tcigTD
// CHECK:         objc_method {{%.*}} : $Foo, #Foo.subscript!getter.uncurried.foreign :

// CHECK-LABEL: sil private [transparent] [thunk] @$s7dynamic3FooCAA5ProtoA2aDPAAS2i_tcisTW
// CHECK:         function_ref @$s7dynamic3FooCAAS2i_tcisTD
// CHECK-LABEL: sil shared [transparent] [serializable] [thunk] @$s7dynamic3FooCAAS2i_tcisTD
// CHECK:         objc_method {{%.*}} : $Foo, #Foo.subscript!setter.uncurried.foreign :

// Superclass dispatch
class Subclass: Foo {
  // Native and objc methods can directly reference super members
  override init(native: Int) {
    super.init(native: native)
  }
  // CHECK-LABEL: sil hidden @$s7dynamic8SubclassC{{[_0-9a-zA-Z]*}}fC
  // CHECK:         function_ref @$s7dynamic8SubclassC{{[_0-9a-zA-Z]*}}fc

  override func nativeMethod() {
    super.nativeMethod()
  }
  // CHECK-LABEL: sil hidden @$s7dynamic8SubclassC12nativeMethod{{[_0-9a-zA-Z]*}}F
  // CHECK:         function_ref @$s7dynamic3FooC12nativeMethodyyF : $@convention(method) (@guaranteed Foo) -> ()

  override var nativeProp: Int {
    get { return super.nativeProp }
    // CHECK-LABEL: sil hidden @$s7dynamic8SubclassC10nativePropSivg
    // CHECK:         function_ref @$s7dynamic3FooC10nativePropSivg : $@convention(method) (@guaranteed Foo) -> Int
    set { super.nativeProp = newValue }
    // CHECK-LABEL: sil hidden @$s7dynamic8SubclassC10nativePropSivs
    // CHECK:         function_ref @$s7dynamic3FooC10nativePropSivs : $@convention(method) (Int, @guaranteed Foo) -> ()
  }

  override subscript(native native: Int) -> Int {
    get { return super[native: native] }
    // CHECK-LABEL: sil hidden @$s7dynamic8SubclassC6nativeS2i_tcig
    // CHECK:         function_ref @$s7dynamic3FooC6nativeS2i_tcig : $@convention(method) (Int, @guaranteed Foo) -> Int
    set { super[native: native] = newValue }
    // CHECK-LABEL: sil hidden @$s7dynamic8SubclassC6nativeS2i_tcis
    // CHECK:         function_ref @$s7dynamic3FooC6nativeS2i_tcis : $@convention(method) (Int, Int, @guaranteed Foo) -> ()
  }

  override init(objc: Int) {
    super.init(objc: objc)
  }
  // CHECK-LABEL: sil hidden @$s7dynamic8SubclassC4objcACSi_tcfc
  // CHECK:         function_ref @$s7dynamic3FooC4objcACSi_tcfc : $@convention(method) (Int, @owned Foo) -> @owned Foo

  override func objcMethod() {
    super.objcMethod()
  }
  // CHECK-LABEL: sil hidden @$s7dynamic8SubclassC10objcMethod{{[_0-9a-zA-Z]*}}F
  // CHECK:         function_ref @$s7dynamic3FooC10objcMethodyyF : $@convention(method) (@guaranteed Foo) -> ()

  override var objcProp: Int {
    get { return super.objcProp }
    // CHECK-LABEL: sil hidden @$s7dynamic8SubclassC8objcPropSivg
    // CHECK:         function_ref @$s7dynamic3FooC8objcPropSivg : $@convention(method) (@guaranteed Foo) -> Int
    set { super.objcProp = newValue }
    // CHECK-LABEL: sil hidden @$s7dynamic8SubclassC8objcPropSivs
    // CHECK:         function_ref @$s7dynamic3FooC8objcPropSivs : $@convention(method) (Int, @guaranteed Foo) -> ()
  }

  override subscript(objc objc: AnyObject) -> Int {
    get { return super[objc: objc] }
    // CHECK-LABEL: sil hidden @$s7dynamic8SubclassC4objcSiyXl_tcig
    // CHECK:         function_ref @$s7dynamic3FooC4objcSiyXl_tcig : $@convention(method) (@guaranteed AnyObject, @guaranteed Foo) -> Int
    set { super[objc: objc] = newValue }
    // CHECK-LABEL: sil hidden @$s7dynamic8SubclassC4objcSiyXl_tcis
    // CHECK:         function_ref @$s7dynamic3FooC4objcSiyXl_tcis : $@convention(method) (Int, @owned AnyObject, @guaranteed Foo) -> ()
  }

  // Dynamic methods are super-dispatched by objc_msgSend
  override init(dynamic: Int) {
    super.init(dynamic: dynamic)
  }
  // CHECK-LABEL: sil hidden @$s7dynamic8SubclassC{{[_0-9a-zA-Z]*}}fc
  // CHECK:         objc_super_method {{%.*}} : $Subclass, #Foo.init!initializer.uncurried.foreign :

  override func dynamicMethod() {
    super.dynamicMethod()
  }
  // CHECK-LABEL: sil hidden @$s7dynamic8SubclassC0A6Method{{[_0-9a-zA-Z]*}}F
  // CHECK:         objc_super_method {{%.*}} : $Subclass, #Foo.dynamicMethod.uncurried.foreign :

  override var dynamicProp: Int {
    get { return super.dynamicProp }
    // CHECK-LABEL: sil hidden @$s7dynamic8SubclassC0A4PropSivg
    // CHECK:         objc_super_method {{%.*}} : $Subclass, #Foo.dynamicProp!getter.uncurried.foreign :
    set { super.dynamicProp = newValue }
    // CHECK-LABEL: sil hidden @$s7dynamic8SubclassC0A4PropSivs
    // CHECK:         objc_super_method {{%.*}} : $Subclass, #Foo.dynamicProp!setter.uncurried.foreign :
  }

  override subscript(dynamic dynamic: Int) -> Int {
    get { return super[dynamic: dynamic] }
    // CHECK-LABEL: sil hidden @$s7dynamic8SubclassCAAS2i_tcig
    // CHECK:         objc_super_method {{%.*}} : $Subclass, #Foo.subscript!getter.uncurried.foreign :
    set { super[dynamic: dynamic] = newValue }
    // CHECK-LABEL: sil hidden @$s7dynamic8SubclassCAAS2i_tcis
    // CHECK:         objc_super_method {{%.*}} : $Subclass, #Foo.subscript!setter.uncurried.foreign :
  }

  @objc dynamic override func overriddenByDynamic() {}
}

class SubclassWithInheritedInits: Foo {
  // CHECK-LABEL: sil hidden @$s7dynamic26SubclassWithInheritedInitsC{{[_0-9a-zA-Z]*}}fc
  // CHECK:         objc_super_method {{%.*}} : $SubclassWithInheritedInits, #Foo.init!initializer.uncurried.foreign :
}
class GrandchildWithInheritedInits: SubclassWithInheritedInits {
  // CHECK-LABEL: sil hidden @$s7dynamic28GrandchildWithInheritedInitsC{{[_0-9a-zA-Z]*}}fc
  // CHECK:         objc_super_method {{%.*}} : $GrandchildWithInheritedInits, #SubclassWithInheritedInits.init!initializer.uncurried.foreign :
}
class GrandchildOfInheritedInits: SubclassWithInheritedInits {
  // Dynamic methods are super-dispatched by objc_msgSend
  override init(dynamic: Int) {
    super.init(dynamic: dynamic)
  }
  // CHECK-LABEL: sil hidden @$s7dynamic26GrandchildOfInheritedInitsC{{[_0-9a-zA-Z]*}}fc
  // CHECK:         objc_super_method {{%.*}} : $GrandchildOfInheritedInits, #SubclassWithInheritedInits.init!initializer.uncurried.foreign :
}

// CHECK-LABEL: sil hidden @$s7dynamic20nativeMethodDispatchyyF : $@convention(thin) () -> ()
func nativeMethodDispatch() {
  // CHECK: function_ref @$s7dynamic3{{[_0-9a-zA-Z]*}}fC
  let c = Foo(native: 0)
  // CHECK: class_method {{%.*}} : $Foo, #Foo.nativeMethod.uncurried :
  c.nativeMethod()
  // CHECK: class_method {{%.*}} : $Foo, #Foo.nativeProp!getter.uncurried :
  let x = c.nativeProp
  // CHECK: class_method {{%.*}} : $Foo, #Foo.nativeProp!setter.uncurried :
  c.nativeProp = x
  // CHECK: class_method {{%.*}} : $Foo, #Foo.subscript!getter.uncurried :
  let y = c[native: 0]
  // CHECK: class_method {{%.*}} : $Foo, #Foo.subscript!setter.uncurried :
  c[native: 0] = y
}

// CHECK-LABEL: sil hidden @$s7dynamic18objcMethodDispatchyyF : $@convention(thin) () -> ()
func objcMethodDispatch() {
  // CHECK: function_ref @$s7dynamic3{{[_0-9a-zA-Z]*}}fC
  let c = Foo(objc: 0)
  // CHECK: class_method {{%.*}} : $Foo, #Foo.objcMethod.uncurried :
  c.objcMethod()
  // CHECK: class_method {{%.*}} : $Foo, #Foo.objcProp!getter.uncurried :
  let x = c.objcProp
  // CHECK: class_method {{%.*}} : $Foo, #Foo.objcProp!setter.uncurried :
  c.objcProp = x
  // CHECK: class_method {{%.*}} : $Foo, #Foo.subscript!getter.uncurried :
  let y = c[objc: 0 as NSNumber]
  // CHECK: class_method {{%.*}} : $Foo, #Foo.subscript!setter.uncurried :
  c[objc: 0 as NSNumber] = y
}

// CHECK-LABEL: sil hidden @$s7dynamic0A14MethodDispatchyyF : $@convention(thin) () -> ()
func dynamicMethodDispatch() {
  // CHECK: function_ref @$s7dynamic3{{[_0-9a-zA-Z]*}}fC
  let c = Foo(dynamic: 0)
  // CHECK: objc_method {{%.*}} : $Foo, #Foo.dynamicMethod.uncurried.foreign 
  c.dynamicMethod()
  // CHECK: objc_method {{%.*}} : $Foo, #Foo.dynamicProp!getter.uncurried.foreign
  let x = c.dynamicProp
  // CHECK: objc_method {{%.*}} : $Foo, #Foo.dynamicProp!setter.uncurried.foreign
  c.dynamicProp = x
  // CHECK: objc_method {{%.*}} : $Foo, #Foo.subscript!getter.uncurried.foreign
  let y = c[dynamic: 0]
  // CHECK: objc_method {{%.*}} : $Foo, #Foo.subscript!setter.uncurried.foreign
  c[dynamic: 0] = y
}

// CHECK-LABEL: sil hidden @$s7dynamic15managedDispatchyyAA3FooCF
func managedDispatch(_ c: Foo) {
  // CHECK: objc_method {{%.*}} : $Foo, #Foo.managedProp!getter.uncurried.foreign 
  let x = c.managedProp
  // CHECK: objc_method {{%.*}} : $Foo, #Foo.managedProp!setter.uncurried.foreign
  c.managedProp = x
}

// CHECK-LABEL: sil hidden @$s7dynamic21foreignMethodDispatchyyF
func foreignMethodDispatch() {
  // CHECK: function_ref @$sSo9GuisemeauC{{[_0-9a-zA-Z]*}}fC
  let g = Guisemeau()!
  // CHECK: objc_method {{%.*}} : $Gizmo, #Gizmo.frob.uncurried.foreign
  g.frob()
  // CHECK: objc_method {{%.*}} : $Gizmo, #Gizmo.count!getter.uncurried.foreign
  let x = g.count
  // CHECK: objc_method {{%.*}} : $Gizmo, #Gizmo.count!setter.uncurried.foreign
  g.count = x
  // CHECK: objc_method {{%.*}} : $Guisemeau, #Guisemeau.subscript!getter.uncurried.foreign
  let y: Any! = g[0]
  // CHECK: objc_method {{%.*}} : $Guisemeau, #Guisemeau.subscript!setter.uncurried.foreign
  g[0] = y
  // CHECK: objc_method {{%.*}} : $NSObject, #NSObject.description!getter.uncurried.foreign
  _ = g.description
}

extension Gizmo {
  // CHECK-LABEL: sil hidden @$sSo5GizmoC7dynamicE{{[_0-9a-zA-Z]*}}fC
  // CHECK:         objc_method {{%.*}} : $Gizmo, #Gizmo.init!initializer.uncurried.foreign
  convenience init(convenienceInExtension: Int) {
    self.init(bellsOn: convenienceInExtension)
  }

  // CHECK-LABEL: sil hidden @$sSo5GizmoC7dynamicE{{[_0-9a-zA-Z]*}}fC
  // CHECK:         objc_method {{%.*}} : $@objc_metatype Gizmo.Type, #Gizmo.init!allocator.uncurried.foreign
  convenience init(foreignClassFactory x: Int) {
    self.init(stuff: x)
  }

  // CHECK-LABEL: sil hidden @$sSo5GizmoC7dynamicE{{[_0-9a-zA-Z]*}}fC
  // CHECK:         objc_method {{%.*}} : $@objc_metatype Gizmo.Type, #Gizmo.init!allocator.uncurried.foreign
  convenience init(foreignClassExactFactory x: Int) {
    self.init(exactlyStuff: x)
  }

  @objc func foreignObjCExtension() { }
  @objc dynamic func foreignDynamicExtension() { }
}

// CHECK-LABEL: sil hidden @$s7dynamic24foreignExtensionDispatchyySo5GizmoCF
// CHECK: bb0([[ARG:%.*]] : @guaranteed $Gizmo):
func foreignExtensionDispatch(_ g: Gizmo) {
  // CHECK: objc_method [[ARG]] : $Gizmo, #Gizmo.foreignObjCExtension.uncurried.foreign : (Gizmo)
  g.foreignObjCExtension()
  // CHECK: objc_method [[ARG]] : $Gizmo, #Gizmo.foreignDynamicExtension.uncurried.foreign
  g.foreignDynamicExtension()
}


// CHECK-LABEL: sil hidden @$s7dynamic33nativeMethodDispatchFromOtherFileyyF : $@convention(thin) () -> ()
func nativeMethodDispatchFromOtherFile() {
  // CHECK: function_ref @$s7dynamic13FromOtherFile{{[_0-9a-zA-Z]*}}fC
  let c = FromOtherFile(native: 0)
  // CHECK: class_method {{%.*}} : $FromOtherFile, #FromOtherFile.nativeMethod.uncurried :
  c.nativeMethod()
  // CHECK: class_method {{%.*}} : $FromOtherFile, #FromOtherFile.nativeProp!getter.uncurried :
  let x = c.nativeProp
  // CHECK: class_method {{%.*}} : $FromOtherFile, #FromOtherFile.nativeProp!setter.uncurried :
  c.nativeProp = x
  // CHECK: class_method {{%.*}} : $FromOtherFile, #FromOtherFile.subscript!getter.uncurried :
  let y = c[native: 0]
  // CHECK: class_method {{%.*}} : $FromOtherFile, #FromOtherFile.subscript!setter.uncurried :
  c[native: 0] = y
}

// CHECK-LABEL: sil hidden @$s7dynamic31objcMethodDispatchFromOtherFileyyF : $@convention(thin) () -> ()
func objcMethodDispatchFromOtherFile() {
  // CHECK: function_ref @$s7dynamic13FromOtherFile{{[_0-9a-zA-Z]*}}fC
  let c = FromOtherFile(objc: 0)
  // CHECK: class_method {{%.*}} : $FromOtherFile, #FromOtherFile.objcMethod.uncurried :
  c.objcMethod()
  // CHECK: class_method {{%.*}} : $FromOtherFile, #FromOtherFile.objcProp!getter.uncurried :
  let x = c.objcProp
  // CHECK: class_method {{%.*}} : $FromOtherFile, #FromOtherFile.objcProp!setter.uncurried :
  c.objcProp = x
  // CHECK: class_method {{%.*}} : $FromOtherFile, #FromOtherFile.subscript!getter.uncurried :
  let y = c[objc: 0]
  // CHECK: class_method {{%.*}} : $FromOtherFile, #FromOtherFile.subscript!setter.uncurried :
  c[objc: 0] = y
}

// CHECK-LABEL: sil hidden @$s7dynamic0A27MethodDispatchFromOtherFileyyF : $@convention(thin) () -> ()
func dynamicMethodDispatchFromOtherFile() {
  // CHECK: function_ref @$s7dynamic13FromOtherFile{{[_0-9a-zA-Z]*}}fC
  let c = FromOtherFile(dynamic: 0)
  // CHECK: objc_method {{%.*}} : $FromOtherFile, #FromOtherFile.dynamicMethod.uncurried.foreign
  c.dynamicMethod()
  // CHECK: objc_method {{%.*}} : $FromOtherFile, #FromOtherFile.dynamicProp!getter.uncurried.foreign
  let x = c.dynamicProp
  // CHECK: objc_method {{%.*}} : $FromOtherFile, #FromOtherFile.dynamicProp!setter.uncurried.foreign
  c.dynamicProp = x
  // CHECK: objc_method {{%.*}} : $FromOtherFile, #FromOtherFile.subscript!getter.uncurried.foreign
  let y = c[dynamic: 0]
  // CHECK: objc_method {{%.*}} : $FromOtherFile, #FromOtherFile.subscript!setter.uncurried.foreign
  c[dynamic: 0] = y
}

// CHECK-LABEL: sil hidden @$s7dynamic28managedDispatchFromOtherFileyyAA0deF0CF
func managedDispatchFromOtherFile(_ c: FromOtherFile) {
  // CHECK: objc_method {{%.*}} : $FromOtherFile, #FromOtherFile.managedProp!getter.uncurried.foreign
  let x = c.managedProp
  // CHECK: objc_method {{%.*}} : $FromOtherFile, #FromOtherFile.managedProp!setter.uncurried.foreign
  c.managedProp = x
}

// CHECK-LABEL: sil hidden @$s7dynamic0A16ExtensionMethodsyyAA13ObjCOtherFileCF
func dynamicExtensionMethods(_ obj: ObjCOtherFile) {
  // CHECK: objc_method {{%.*}} : $ObjCOtherFile, #ObjCOtherFile.extensionMethod.uncurried.foreign
  obj.extensionMethod()
  // CHECK: objc_method {{%.*}} : $ObjCOtherFile, #ObjCOtherFile.extensionProp!getter.uncurried.foreign
  _ = obj.extensionProp

  // CHECK: thick_to_objc_metatype {{%.*}} : $@thick ObjCOtherFile.Type to $@objc_metatype ObjCOtherFile.Type
  // CHECK-NEXT: objc_method {{%.*}} : $@objc_metatype ObjCOtherFile.Type, #ObjCOtherFile.extensionClassProp!getter.uncurried.foreign
  _ = type(of: obj).extensionClassProp

  // CHECK: objc_method {{%.*}} : $ObjCOtherFile, #ObjCOtherFile.dynExtensionMethod.uncurried.foreign
  obj.dynExtensionMethod()
  // CHECK: objc_method {{%.*}} : $ObjCOtherFile, #ObjCOtherFile.dynExtensionProp!getter.uncurried.foreign
  _ = obj.dynExtensionProp

  // CHECK: thick_to_objc_metatype {{%.*}} : $@thick ObjCOtherFile.Type to $@objc_metatype ObjCOtherFile.Type
  // CHECK-NEXT: objc_method {{%.*}} : $@objc_metatype ObjCOtherFile.Type, #ObjCOtherFile.dynExtensionClassProp!getter.uncurried.foreign
  _ = type(of: obj).dynExtensionClassProp
}

public class Base {
  @objc dynamic var x: Bool { return false }
}

public class Sub : Base {
  // CHECK-LABEL: sil hidden @$s7dynamic3SubC1xSbvg : $@convention(method) (@guaranteed Sub) -> Bool {
  // CHECK: bb0([[SELF:%.*]] : @guaranteed $Sub):
  // CHECK:     [[AUTOCLOSURE:%.*]] = function_ref @$s7dynamic3SubC1xSbvgSbyKXEfu_ : $@convention(thin) (@guaranteed Sub) -> (Bool, @error Error)
  // CHECK:     [[SELF_COPY:%.*]] = copy_value [[SELF]]
  // CHECK:     = partial_apply [callee_guaranteed] [[AUTOCLOSURE]]([[SELF_COPY]])
  // CHECK:     return {{%.*}} : $Bool
  // CHECK: } // end sil function '$s7dynamic3SubC1xSbvg'

  // CHECK-LABEL: sil private [transparent] @$s7dynamic3SubC1xSbvgSbyKXEfu_ : $@convention(thin) (@guaranteed Sub) -> (Bool, @error Error) {
  // CHECK: bb0([[VALUE:%.*]] : @guaranteed $Sub):
  // CHECK:     [[VALUE_COPY:%.*]] = copy_value [[VALUE]]
  // CHECK:     [[CAST_VALUE_COPY:%.*]] = upcast [[VALUE_COPY]]
  // CHECK:     [[BORROWED_CAST_VALUE_COPY:%.*]] = begin_borrow [[CAST_VALUE_COPY]]
  // CHECK:     [[DOWNCAST_FOR_SUPERMETHOD:%.*]] = unchecked_ref_cast [[BORROWED_CAST_VALUE_COPY]]
  // CHECK:     [[SUPER:%.*]] = objc_super_method [[DOWNCAST_FOR_SUPERMETHOD]] : $Sub, #Base.x!getter.uncurried.foreign : (Base) -> () -> Bool, $@convention(objc_method) (Base) -> ObjCBool
  // CHECK:     = apply [[SUPER]]([[BORROWED_CAST_VALUE_COPY]])
  // CHECK:     end_borrow [[BORROWED_CAST_VALUE_COPY]]
  // CHECK:     destroy_value [[CAST_VALUE_COPY]]
  // CHECK: } // end sil function '$s7dynamic3SubC1xSbvgSbyKXEfu_'
  override var x: Bool { return false || super.x }
}

public class BaseExt : NSObject {}

extension BaseExt {
  @objc public var count: Int {
    return 0
  }
}

public class SubExt : BaseExt {
  public override var count: Int {
    return 1
  }
}

public class GenericBase<T> {
  public func method(_: T) {}
}

public class ConcreteDerived : GenericBase<Int> {
  @objc public override dynamic func method(_: Int) {}
}

// The dynamic override has a different calling convention than the base,
// so after re-abstracting the signature we must dispatch to the dynamic
// thunk.

// CHECK-LABEL: sil private @$s7dynamic15ConcreteDerivedC6methodyySiFAA11GenericBaseCADyyxFTV : $@convention(method) (@in_guaranteed Int, @guaranteed ConcreteDerived) -> ()
// CHECK: bb0(%0 : @trivial $*Int, %1 : @guaranteed $ConcreteDerived):
// CHECK-NEXT:  [[VALUE:%.*]] = load [trivial] %0 : $*Int
// CHECK:       [[DYNAMIC_THUNK:%.*]] = function_ref @$s7dynamic15ConcreteDerivedC6methodyySiFTD : $@convention(method) (Int, @guaranteed ConcreteDerived) -> ()
// CHECK-NEXT:  apply [[DYNAMIC_THUNK]]([[VALUE]], %1) : $@convention(method) (Int, @guaranteed ConcreteDerived) -> ()
// CHECK:       return

// Vtable contains entries for native and @objc methods, but not dynamic ones
// CHECK-LABEL: sil_vtable Foo {
// CHECK-NEXT:   #Foo.init!allocator.uncurried: {{.*}} :   @$s7dynamic3FooC6nativeACSi_tcfC
// CHECK-NEXT:   #Foo.nativeMethod.uncurried: {{.*}} :       @$s7dynamic3FooC12nativeMethodyyF
// CHECK-NEXT:   #Foo.nativeProp!getter.uncurried: {{.*}} :  @$s7dynamic3FooC10nativePropSivg     // dynamic.Foo.nativeProp.getter : Swift.Int
// CHECK-NEXT:   #Foo.nativeProp!setter.uncurried: {{.*}} :  @$s7dynamic3FooC10nativePropSivs     // dynamic.Foo.nativeProp.setter : Swift.Int
// CHECK-NEXT:   #Foo.nativeProp!modify.uncurried:
// CHECK-NEXT:   #Foo.subscript!getter.uncurried: {{.*}} :   @$s7dynamic3FooC6nativeS2i_tcig    // dynamic.Foo.subscript.getter : (native: Swift.Int) -> Swift.Int
// CHECK-NEXT:   #Foo.subscript!setter.uncurried: {{.*}} :   @$s7dynamic3FooC6nativeS2i_tcis    // dynamic.Foo.subscript.setter : (native: Swift.Int) -> Swift.Int
// CHECK-NEXT:   #Foo.subscript!modify.uncurried:
// CHECK-NEXT:   #Foo.init!allocator.uncurried: {{.*}} :   @$s7dynamic3FooC4objcACSi_tcfC
// CHECK-NEXT:   #Foo.objcMethod.uncurried: {{.*}} :         @$s7dynamic3FooC10objcMethodyyF
// CHECK-NEXT:   #Foo.objcProp!getter.uncurried: {{.*}} :    @$s7dynamic3FooC8objcPropSivg  // dynamic.Foo.objcProp.getter : Swift.Int
// CHECK-NEXT:   #Foo.objcProp!setter.uncurried: {{.*}} :    @$s7dynamic3FooC8objcPropSivs  // dynamic.Foo.objcProp.setter : Swift.Int
// CHECK-NEXT:   #Foo.objcProp!modify.uncurried:
// CHECK-NEXT:   #Foo.subscript!getter.uncurried: {{.*}} : @$s7dynamic3FooC4objcSiyXl_tcig // dynamic.Foo.subscript.getter : (objc: Swift.AnyObject) -> Swift.Int
// CHECK-NEXT:   #Foo.subscript!setter.uncurried: {{.*}} : @$s7dynamic3FooC4objcSiyXl_tcis // dynamic.Foo.subscript.setter : (objc: Swift.AnyObject) -> Swift.Int
// CHECK-NEXT:   #Foo.subscript!modify.uncurried:
// CHECK-NEXT:   #Foo.overriddenByDynamic.uncurried: {{.*}} : @$s7dynamic3FooC19overriddenByDynamic{{[_0-9a-zA-Z]*}}
// CHECK-NEXT:   #Foo.deinit!deallocator.uncurried: {{.*}}
// CHECK-NEXT: }

// Vtable uses a dynamic thunk for dynamic overrides
// CHECK-LABEL: sil_vtable Subclass {
// CHECK:   #Foo.overriddenByDynamic.uncurried: {{.*}} : public @$s7dynamic8SubclassC19overriddenByDynamic{{[_0-9a-zA-Z]*}}FTD
// CHECK: }

// Check vtables for implicitly-inherited initializers
// CHECK-LABEL: sil_vtable SubclassWithInheritedInits {
// CHECK:   #Foo.init!allocator.uncurried: (Foo.Type) -> (Int) -> Foo : @$s7dynamic26SubclassWithInheritedInitsC6nativeACSi_tcfC
// CHECK:   #Foo.init!allocator.uncurried: (Foo.Type) -> (Int) -> Foo : @$s7dynamic26SubclassWithInheritedInitsC4objcACSi_tcfC
// CHECK-NOT: .init!
// CHECK: }

// CHECK-LABEL: sil_vtable GrandchildWithInheritedInits {
// CHECK:   #Foo.init!allocator.uncurried: (Foo.Type) -> (Int) -> Foo : @$s7dynamic28GrandchildWithInheritedInitsC6nativeACSi_tcfC
// CHECK:   #Foo.init!allocator.uncurried: (Foo.Type) -> (Int) -> Foo : @$s7dynamic28GrandchildWithInheritedInitsC4objcACSi_tcfC
// CHECK-NOT: .init!
// CHECK: }

// CHECK-LABEL: sil_vtable GrandchildOfInheritedInits {
// CHECK:   #Foo.init!allocator.uncurried: (Foo.Type) -> (Int) -> Foo : @$s7dynamic26GrandchildOfInheritedInitsC6nativeACSi_tcfC
// CHECK:   #Foo.init!allocator.uncurried: (Foo.Type) -> (Int) -> Foo : @$s7dynamic26GrandchildOfInheritedInitsC4objcACSi_tcfC
// CHECK-NOT: .init!
// CHECK: }

// No vtable entry for override of @objc extension property
// CHECK-LABEL: sil_vtable [serialized] SubExt {
// CHECK-NEXT: #SubExt.deinit!deallocator.uncurried: @$s7dynamic6SubExtCfD // dynamic.SubExt.__deallocating_deinit
// CHECK-NEXT: }

// Dynamic thunk + vtable re-abstraction
// CHECK-LABEL: sil_vtable [serialized] ConcreteDerived {
// CHECK-NEXT: #GenericBase.method.uncurried: <T> (GenericBase<T>) -> (T) -> () : public @$s7dynamic15ConcreteDerivedC6methodyySiFAA11GenericBaseCADyyxFTV [override]     // vtable thunk for dynamic.GenericBase.method(A) -> () dispatching to dynamic.ConcreteDerived.method(Swift.Int) -> ()
// CHECK-NEXT: #GenericBase.init!allocator.uncurried: <T> (GenericBase<T>.Type) -> () -> GenericBase<T> : @$s7dynamic15ConcreteDerivedCACycfC [override]
// CHECK-NEXT: #ConcreteDerived.deinit!deallocator.uncurried: @$s7dynamic15ConcreteDerivedCfD  // dynamic.ConcreteDerived.__deallocating_deinit
// CHECK-NEXT: }
