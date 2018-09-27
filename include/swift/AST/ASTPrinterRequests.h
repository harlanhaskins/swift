//===------ ASTPrinterRequests.h - Requests for the AST Printer ----------===//
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

#ifndef SWIFT_AST_ASTPRINTERREQUESTS_H
#define SWIFT_AST_ASTPRINTERREQUESTS_H

#include "swift/AST/SimpleRequest.h"
#include "swift/Basic/Statistic.h"
#include "llvm/ADT/TinyPtrVector.h"


namespace swift {
class NominalTypeDecl;

class HasInlinableInitializerRequest :
  public SimpleRequest<HasInlinableInitializerRequest,
    CacheKind::Cached, bool, NominalTypeDecl *> {
public:
  using SimpleRequest::SimpleRequest;

private:
  friend SimpleRequest;

  // Evaluation.
  bool evaluate(Evaluator &evaluator, NominalTypeDecl *decl) const;

public:
  // Caching
  bool isCached() const { return true; }

  // Cycle handling
  void diagnoseCycle(DiagnosticEngine &diags) const;
  void noteCycleStep(DiagnosticEngine &diags) const;
};

/// The zone number for ASTPrinter requests.
#define SWIFT_AST_PRINTER_REQUESTS_TYPEID_ZONE 12

#define SWIFT_TYPEID_ZONE SWIFT_AST_PRINTER_REQUESTS_TYPEID_ZONE
#define SWIFT_TYPEID_HEADER "swift/AST/ASTPrinterTypeIDZone.def"
#include "swift/Basic/DefineTypeIDZone.h"
#undef SWIFT_TYPEID_ZONE
#undef SWIFT_TYPEID_HEADER

// Set up reporting of evaluated requests.
template<typename Request>
void reportEvaluatedRequest(UnifiedStatsReporter &stats,
                            const Request &request);

#define SWIFT_TYPEID(RequestType)                                \
template<>                                                       \
inline void reportEvaluatedRequest(UnifiedStatsReporter &stats,  \
                            const RequestType &request) {        \
  ++stats.getFrontendCounters().RequestType;                     \
}
#include "swift/AST/ASTPrinterTypeIDZone.def"
#undef SWIFT_TYPEID

} // end namespace swift

#endif // defined(SWIFT_AST_ASTPRINTERREQUESTS_H)
