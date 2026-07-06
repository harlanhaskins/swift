// RUN: %target-run-simple-swift( -Xfrontend -disable-availability-checking %import-libdispatch -parse-as-library) | %FileCheck %s --dump-input=always

// REQUIRES: executable_test
// REQUIRES: concurrency
// REQUIRES: libdispatch
// REQUIRES: concurrency_runtime
// UNSUPPORTED: back_deployment_runtime

import Synchronization

// A client-side reduction of the observation events into the two clocks
// described by the design: a "cost" clock (on-CPU time only) and a "timeout"
// clock contribution (the time the subtree was runnable but starved of a
// thread, which a timeout clock would subtract from wall time).
//
// The subtree is starved at an instant exactly when no task is running and at
// least one is runnable, so the union of per-task starvation intervals is read
// straight off the two counts rather than by merging intervals.
final class ExecutionClocks: Sendable {
  struct State {
    var running = 0
    var runnable = 0
    var starvedSince: ContinuousClock.Instant? = nil

    // Per-slice start times, keyed by task id. A task never runs in two places
    // at once, so at most one slice per id is open at a time.
    var sliceStart: [UInt64: ContinuousClock.Instant] = [:]

    var cost: Duration = .zero
    var starvation: Duration = .zero

    var startCount = 0
    var stopCount = 0
    var becameRunnableCount = 0
    var completeCount = 0
    var observedIDs: Set<UInt64> = []
  }

  let clock = ContinuousClock()
  let state = Mutex(State())

  // Recompute the starvation region after a count change.
  private func updateStarvation(_ s: inout State) {
    let starvedNow = (s.running == 0 && s.runnable > 0)
    switch (s.starvedSince, starvedNow) {
    case (nil, true):
      s.starvedSince = clock.now
    case (.some(let since), false):
      s.starvation += clock.now - since
      s.starvedSince = nil
    default:
      break
    }
  }

  func onEvent(_ info: ExecutingTaskInfo, _ event: TaskExecutionEvent) {
    state.withLock { s in
      switch event {
      case .becameRunnable:
        s.becameRunnableCount += 1
        s.observedIDs.insert(info.id)
        s.runnable += 1
        updateStarvation(&s)
      case .startedRunning:
        s.startCount += 1
        s.observedIDs.insert(info.id)
        if s.runnable > 0 { s.runnable -= 1 }
        s.running += 1
        s.sliceStart[info.id] = clock.now
        updateStarvation(&s)
      case .stoppedRunning:
        s.stopCount += 1
        if let start = s.sliceStart.removeValue(forKey: info.id) {
          s.cost += clock.now - start
        }
        if s.running > 0 { s.running -= 1 }
        updateStarvation(&s)
      case .completed:
        s.completeCount += 1
      }
    }
  }
}

@available(SwiftStdlib 6.5, *)
func spin(_ iterations: Int) -> Int {
  var acc = 0
  for i in 0..<iterations { acc = acc &+ (i &* 31) % 1_000_003 }
  return acc
}

@main
struct Main {
  static func main() async {
    let clocks = ExecutionClocks()

    // Run the observation inside its own task so the observed root completes
    // cleanly (and its final slice's stoppedRunning fires). Observing the main
    // task directly would leave its last slice unbalanced, since the runtime
    // exits the process from inside that slice rather than returning from it.
    let result = await Task {
      await withTaskExecutionObservation {
        // A detached task does not inherit the observation: its work outlives the
        // scope, so it must never be observed. Its initial enqueue happens
        // synchronously here, so if it *were* observed it would show up below.
        let detached = Task.detached {
          _ = spin(10_000)
        }

        // Some on-CPU work, a real wait, then a structured child that also mixes
        // compute and waiting. The child inherits the observation.
        var total = spin(50_000)
        try? await Task.sleep(for: .milliseconds(5))

        async let child: Int = {
          var sub = spin(50_000)
          try? await Task.sleep(for: .milliseconds(5))
          sub &+= spin(50_000)
          return sub
        }()

        total &+= spin(50_000)
        total &+= await child

        await detached.value
        return total
      } onEvent: { clocks.onEvent($0, $1) }
    }.value

    _ = result

    let snapshot = clocks.state.withLock { $0 }

    // The completed event fires exactly once, at scope exit.
    print("complete once: \(snapshot.completeCount == 1)")
    // CHECK: complete once: true

    // The run bracket is strictly paired per slice.
    print("brackets balanced: \(snapshot.startCount == snapshot.stopCount && snapshot.startCount > 0)")
    // CHECK: brackets balanced: true

    // The subtree made itself runnable at least once (sleeps + child enqueue).
    print("became runnable: \(snapshot.becameRunnableCount > 0)")
    // CHECK: became runnable: true

    // The structured child was observed: more than just the root task ran.
    print("child observed: \(snapshot.observedIDs.count > 1)")
    // CHECK: child observed: true

    // Exactly two tasks were observed -- the root and its one async-let child.
    // The detached task would be a third if it had wrongly inherited.
    print("detached not observed: \(snapshot.observedIDs.count == 2)")
    // CHECK: detached not observed: true

    // The cost clock accumulated real on-CPU time.
    print("cost positive: \(snapshot.cost > .zero)")
    // CHECK: cost positive: true

    print("done")
    // CHECK: done
  }
}
