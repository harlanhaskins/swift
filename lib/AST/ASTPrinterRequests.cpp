//===------ ASTPrinterRequests.cpp - Requests for the ASTPrinter ----------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

#include "swift/AST/ASTPrinterRequests.h"
#include "swift/AST/ASTContext.h"
#include "swift/AST/Decl.h"
#include "swift/Subsystems.h"

using namespace swift;

namespace swift {
// Implement the ASTPrinter type zone.
#define SWIFT_TYPEID_ZONE SWIFT_ASTPRINTER_REQUESTS_TYPEID_ZONE
#define SWIFT_TYPEID_HEADER "swift/AST/ASTPrinterTypeIDZone.def"
#include "swift/Basic/ImplementTypeIDZone.h"
#undef SWIFT_TYPEID_ZONE
#undef SWIFT_TYPEID_HEADER
}

void HasInlinableInitializerRequest::diagnoseCycle(
  DiagnosticEngine &diags) const {
  auto storage = std::get<0>(getStorage());
  diags.diagnose(storage, diag::circular_reference);
}

void HasInlinableInitializerRequest::noteCycleStep(
  DiagnosticEngine &diags) const {
  auto storage = std::get<0>(getStorage());
  diags.diagnose(storage, diag::circular_reference_through);
}

static bool hasInlinableInit(IterableDeclContext *dc) {
  for (auto *member : dc->getMembers()) {
    auto init = dyn_cast<ConstructorDecl>(member);
    if (!init) continue;

    if (init->getResilienceExpansion() == ResilienceExpansion::Minimal)
      return true;
  }
  return false;
}

bool HasInlinableInitializerRequest::evaluate(
  Evaluator &evaluator, NominalTypeDecl *decl) const {
  if (hasInlinableInit(decl))
    return true;
  for (auto *ext : decl->getExtensions()) {
    if (hasInlinableInit(ext))
      return true;
  }
  return false;
}

// Define request evaluation functions for each of the ASTPrinter requests.
static AbstractRequestFunction *astPrinterRequestFunctions[] = {
#define SWIFT_TYPEID(Name)                                    \
  reinterpret_cast<AbstractRequestFunction *>(&Name::evaluateRequest),
#include "swift/AST/ASTPrinterTypeIDZone.def"
#undef SWIFT_TYPEID
};

void swift::registerASTPrinterRequestFunctions(Evaluator &evaluator) {
  evaluator.registerRequestFunctions(SWIFT_AST_PRINTER_REQUESTS_TYPEID_ZONE,
                                     astPrinterRequestFunctions);
}
