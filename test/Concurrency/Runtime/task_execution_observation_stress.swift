// RUN: %target-run-simple-swift( -Xfrontend -disable-availability-checking %import-libdispatch -parse-as-library) | %FileCheck %s

// REQUIRES: executable_test
// REQUIRES: concurrency
// REQUIRES: libdispatch
// REQUIRES: concurrency_runtime
// UNSUPPORTED: back_deployment_runtime

// Stress test for withTaskExecutionObservation: drive many independent
// observations concurrently, with deep fan-out and contention, to shake out
// races in the per-slice record retain/release, the flag/record propagation to
// structured children, and nested observation scopes. Each scope verifies its
// own invariants; the run passes only if every scope held them.

import Synchronization

// Per-scope reduction of the observation signals, with the invariants a correct
// observation must satisfy once its root task has completed normally.
final class ScopeRecorder: Sendable {
  struct State {
    var running = 0
    var runnable = 0
    var underflowed = false

    var startCount = 0
    var stopCount = 0
    var becameRunnableCount = 0
    var completeCount = 0
    var observedIDs: Set<UInt64> = []
  }

  let state = Mutex(State())

  func onEvent(_ info: ExecutingTaskInfo, _ event: TaskExecutionEvent) {
    state.withLock { s in
      switch event {
      case .becameRunnable:
        s.becameRunnableCount += 1
        s.observedIDs.insert(info.id)
        s.runnable += 1
      case .startedRunning:
        s.startCount += 1
        s.observedIDs.insert(info.id)
        if s.runnable > 0 { s.runnable -= 1 } else { s.underflowed = true }
        s.running += 1
      case .stoppedRunning:
        s.stopCount += 1
        if s.running > 0 { s.running -= 1 } else { s.underflowed = true }
      case .completed:
        s.completeCount += 1
      }
    }
  }

  /// Invariants that hold as soon as the observed body has returned, regardless
  /// of when the still-in-flight final slices fire their run-stop (the awaiter
  /// can resume before a completing task's onStopRunning runs, so exact
  /// start/stop balance is inherently racy to read and is covered by the
  /// non-stress test instead). What must hold here:
  ///   - the scope completed exactly once,
  ///   - real activity was observed (slices ran, the subtree became runnable),
  ///   - every became-runnable was consumed by a run-start (runnable drained),
  ///   - no count ever underflowed -- i.e. no run-stop without a matching
  ///     run-start, and no run-start without a preceding became-runnable.
  var isValid: Bool {
    state.withLock { s in
      s.completeCount == 1
        && s.startCount > 0
        && s.stopCount > 0
        && s.becameRunnableCount > 0
        && s.runnable == 0
        && !s.underflowed
    }
  }
}

@available(SwiftStdlib 6.5, *)
func spin(_ iterations: Int) -> Int {
  var acc = 0
  for i in 0..<iterations { acc = acc &+ (i &* 2654435761) % 1_000_003 }
  return acc
}

// One observed subtree: a task group with fan-out plus an async let, each child
// alternating compute and a short real wait so the cooperative pool churns.
@available(SwiftStdlib 6.5, *)
func observedWorkload(children: Int) async -> Int {
  await withTaskGroup(of: Int.self) { group in
    for k in 0..<children {
      group.addTask {
        var acc = spin(20_000)
        try? await Task.sleep(for: .milliseconds(1 + (k % 3)))
        acc &+= spin(20_000)
        return acc
      }
    }
    async let extra: Int = {
      try? await Task.sleep(for: .milliseconds(1))
      return spin(20_000)
    }()
    var total = 0
    for await partial in group { total &+= partial }
    total &+= await extra
    return total
  }
}

@available(SwiftStdlib 6.5, *)
func runObservedScope(children: Int) async -> Bool {
  let recorder = ScopeRecorder()
  _ = await withTaskExecutionObservation {
    await observedWorkload(children: children)
  } onEvent: { recorder.onEvent($0, $1) }
  return recorder.isValid
}

// A nested observation: an inner scope runs inside the outer scope's body on the
// same root task. While the inner scope is active the root's slices are
// attributed to the inner record; the outer record is restored afterwards. Both
// must end balanced and complete exactly once.
@available(SwiftStdlib 6.5, *)
func runNestedScope() async -> Bool {
  let outer = ScopeRecorder()
  let inner = ScopeRecorder()
  _ = await withTaskExecutionObservation {
    _ = await observedWorkload(children: 4)
    _ = await withTaskExecutionObservation {
      await observedWorkload(children: 4)
    } onEvent: { inner.onEvent($0, $1) }
    _ = await observedWorkload(children: 4)
  } onEvent: { outer.onEvent($0, $1) }
  return outer.isValid && inner.isValid
}

@main
struct Main {
  static func main() async {
    let concurrentScopes = 64
    let childrenPerScope = 8
    let nestedScopes = 16

    let violations = Atomic<Int>(0)

    // Many independent observations running at once: this is what exercises the
    // per-slice retain/release of distinct records across threads concurrently.
    await withTaskGroup(of: Void.self) { group in
      for _ in 0..<concurrentScopes {
        group.addTask {
          if await !runObservedScope(children: childrenPerScope) {
            violations.add(1, ordering: .relaxed)
          }
        }
      }
      for _ in 0..<nestedScopes {
        group.addTask {
          if await !runNestedScope() {
            violations.add(1, ordering: .relaxed)
          }
        }
      }
      await group.waitForAll()
    }

    let totalScopes = concurrentScopes + nestedScopes
    print("scopes run: \(totalScopes)")
    // CHECK: scopes run: 80

    print("violations: \(violations.load(ordering: .relaxed))")
    // CHECK: violations: 0

    print("done")
    // CHECK: done
  }
}
