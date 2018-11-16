// RUN: %target-swift-emit-silgen -parse-as-library -enable-sil-ownership %s | %FileCheck %s

// Only derived classes with non-trivial ivars need an ivar destroyer.

struct TrivialStruct {}

class RootClassWithoutProperties {}

class RootClassWithTrivialProperties {
  var x: Int = 0
  var y: TrivialStruct = TrivialStruct()
}

class Canary {}

class RootClassWithNonTrivialProperties {
  var x: Canary = Canary()
}

class DerivedClassWithTrivialProperties : RootClassWithoutProperties {
  var z: Int = 12
}

class DerivedClassWithNonTrivialProperties : RootClassWithoutProperties {
  var z: Canary = Canary()
}

// CHECK-LABEL: sil hidden @$s14ivar_destroyer36DerivedClassWithNonTrivialPropertiesCfE
// CHECK:       bb0(%0 : @guaranteed $DerivedClassWithNonTrivialProperties):
// CHECK-NEXT:    debug_value %0
// CHECK-NEXT:    [[Z_ADDR:%.*]] = ref_element_addr %0
// CHECK-NEXT:    destroy_addr [[Z_ADDR]]
// CHECK-NEXT:    [[RESULT:%.*]] = tuple ()
// CHECK-NEXT:    return [[RESULT]]

// CHECK-LABEL: sil_vtable RootClassWithoutProperties {
// CHECK-NEXT:    #RootClassWithoutProperties.init!allocator.uncurried
// CHECK-NEXT:    #RootClassWithoutProperties.deinit!deallocator
// CHECK-NEXT:  }

// CHECK-LABEL: sil_vtable RootClassWithTrivialProperties {
// CHECK-NEXT:    #RootClassWithTrivialProperties.x!getter.uncurried
// CHECK-NEXT:    #RootClassWithTrivialProperties.x!setter.uncurried
// CHECK-NEXT:    #RootClassWithTrivialProperties.x!modify.uncurried
// CHECK-NEXT:    #RootClassWithTrivialProperties.y!getter.uncurried
// CHECK-NEXT:    #RootClassWithTrivialProperties.y!setter.uncurried
// CHECK-NEXT:    #RootClassWithTrivialProperties.y!modify.uncurried
// CHECK-NEXT:    #RootClassWithTrivialProperties.init!allocator.uncurried
// CHECK-NEXT:    #RootClassWithTrivialProperties.deinit!deallocator
// CHECK-NEXT:  }

// CHECK-LABEL: sil_vtable RootClassWithNonTrivialProperties {
// CHECK-NEXT:    #RootClassWithNonTrivialProperties.x!getter.uncurried
// CHECK-NEXT:    #RootClassWithNonTrivialProperties.x!setter.uncurried
// CHECK-NEXT:    #RootClassWithNonTrivialProperties.x!modify.uncurried
// CHECK-NEXT:    #RootClassWithNonTrivialProperties.init!allocator.uncurried
// CHECK-NEXT:    #RootClassWithNonTrivialProperties.deinit!deallocator
// CHECK-NEXT:  }

// CHECK-LABEL: sil_vtable DerivedClassWithTrivialProperties {
// CHECK-NEXT:    #RootClassWithoutProperties.init!allocator.uncurried
// CHECK-NEXT:    #DerivedClassWithTrivialProperties.z!getter.uncurried
// CHECK-NEXT:    #DerivedClassWithTrivialProperties.z!setter.uncurried
// CHECK-NEXT:    #DerivedClassWithTrivialProperties.z!modify.uncurried
// CHECK-NEXT:    #DerivedClassWithTrivialProperties.deinit!deallocator
// CHECK-NEXT:  }

// CHECK-LABEL: sil_vtable DerivedClassWithNonTrivialProperties {
// CHECK-NEXT:    #RootClassWithoutProperties.init!allocator.uncurried
// CHECK-NEXT:    #DerivedClassWithNonTrivialProperties.z!getter.uncurried
// CHECK-NEXT:    #DerivedClassWithNonTrivialProperties.z!setter.uncurried
// CHECK-NEXT:    #DerivedClassWithNonTrivialProperties.z!modify.uncurried
// CHECK-NEXT:    #DerivedClassWithNonTrivialProperties.deinit!deallocator
// CHECK-NEXT:    #DerivedClassWithNonTrivialProperties!ivardestroyer.1
// CHECK-NEXT:  }
