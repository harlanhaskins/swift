//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Swift

// ==== Task Execution Observation ---------------------------------------------
//
// Observes the scheduling-state transitions of a task and the structured
// subtree it spawns, surfacing the signals that distinguish work from
// contention. From these a client can derive a "cost" clock (on-CPU time only)
// and a "timeout" clock (wall time minus the time the subtree was runnable but
// starved of a thread). The runtime only surfaces the signals; the policy of
// what to measure and how to accumulate it lives in the callback.

/// Information about a task whose execution is being observed by
/// ``withTaskExecutionObservation(operation:onEvent:isolation:)``.
///
/// Several tasks in an observed subtree may run concurrently, so the callback
/// uses ``id`` to attribute an event to the right task. The value is read-only
/// and does not extend the observed task's lifetime.
@available(SwiftStdlib 6.5, *)
@frozen
public struct ExecutingTaskInfo: Sendable, Hashable {
  /// A stable identifier for the observed task, equal to the identity reported
  /// by `Task` for the same task.
  public let id: UInt64

  internal init(id: UInt64) {
    self.id = id
  }
}

/// A transition in the scheduling state of an observed task.
///
/// The raw values are part of the ABI contract with the runtime chokepoints
/// that raise these events; keep them in sync with `TaskExecutionEventKind` in
/// TaskPrivate.h.
@available(SwiftStdlib 6.5, *)
@frozen
public enum TaskExecutionEvent: Sendable, Hashable {
  /// A slice of the task is about to run, on the slice's own thread. Paired
  /// with a later ``stoppedRunning`` on the same thread; the pair brackets one
  /// continuous span of on-CPU occupancy.
  case startedRunning

  /// A slice of the task just stopped running, on the slice's own thread.
  case stoppedRunning

  /// The task became eligible to run again -- the moment it is enqueued onto an
  /// executor. The interval from here to the next ``startedRunning`` is the
  /// time the task was runnable but starved of a thread.
  case becameRunnable

  /// The observed root completed; finalize or read any accumulated totals.
  case completed
}

// MARK: - Runtime entry points

@available(SwiftStdlib 6.5, *)
@_silgen_name("swift_task_startExecutionObservation")
internal func _startTaskExecutionObservation(
  _ record: UnsafeMutableRawPointer
) -> UnsafeMutableRawPointer?

@available(SwiftStdlib 6.5, *)
@_silgen_name("swift_task_stopExecutionObservation")
internal func _stopTaskExecutionObservation(
  _ record: UnsafeMutableRawPointer,
  _ previous: UnsafeMutableRawPointer?
)

@available(SwiftStdlib 6.5, *)
@_silgen_name("swift_task_getCurrentTaskId")
internal func _getCurrentTaskId() -> UInt64

// MARK: - Observation record

/// Type-erased storage for the callback of one observation scope, shared by the
/// observed task and the structured subtree it spawns.
///
/// The runtime holds this record at +1 for the lifetime of the scope (released
/// by `swift_task_stopExecutionObservation`), and each per-slice run bracket
/// retains it for that slice's duration. That extra retain is what keeps the
/// record -- and the closure it owns -- valid for a slice that races the
/// teardown of its own observation scope.
@available(SwiftStdlib 6.5, *)
final internal class _TaskExecutionObservationRecord {
  internal let onEvent: @Sendable (ExecutingTaskInfo, TaskExecutionEvent) -> Void

  internal init(
    onEvent: @escaping @Sendable (ExecutingTaskInfo, TaskExecutionEvent) -> Void
  ) {
    self.onEvent = onEvent
  }
}

// MARK: - Runtime callback trampoline
//
// Called from the C++ run and enqueue chokepoints. `record` is the opaque
// pointer stored on the observed task; it is borrowed here -- the caller
// guarantees the record outlives the call. `kind` mirrors the
// TaskExecutionEventKind enum in TaskPrivate.h.

@available(SwiftStdlib 6.5, *)
@_silgen_name("_swift_taskExecutionObservation_onEvent")
internal func _taskExecutionObservation_onEvent(
  _ record: UnsafeMutableRawPointer,
  _ taskId: UInt64,
  _ kind: UInt8
) {
  let observation = unsafe Unmanaged<_TaskExecutionObservationRecord>
    .fromOpaque(record).takeUnretainedValue()
  let event: TaskExecutionEvent
  switch kind {
  case 0: event = .startedRunning
  case 1: event = .stoppedRunning
  case 2: event = .becameRunnable
  default: event = .completed
  }
  observation.onEvent(ExecutingTaskInfo(id: taskId), event)
}

// MARK: - Public API

/// Observe the execution of `operation` and the structured subtree of tasks it
/// spawns.
///
/// The observation covers the current task and any structured children it
/// creates while `operation` runs -- `async let`, task groups, and child tasks
/// that inherit context. Detached and context-discarding tasks do not inherit
/// the observation, because their work outlives this scope.
///
/// `onEvent` is called once per scheduling-state transition (see
/// ``TaskExecutionEvent``):
///
/// - ``TaskExecutionEvent/startedRunning`` and
///   ``TaskExecutionEvent/stoppedRunning`` bracket one slice -- one continuous
///   span of on-CPU occupancy of a thread -- and fire on that thread. They fire
///   once per slice, not once per task.
/// - ``TaskExecutionEvent/becameRunnable`` fires when the task is enqueued onto
///   an executor; the gap to the next `startedRunning` is starvation time.
/// - ``TaskExecutionEvent/completed`` fires once after `operation` returns.
///
/// To accumulate per-slice deltas (for example, a cost clock), correlate
/// `startedRunning` and `stoppedRunning` by ``ExecutingTaskInfo/id``: the pair
/// is delivered on one thread and a task is never running in two places at
/// once, so at most one slice per task is open at a time.
///
/// - Important: The callback runs inside hot runtime chokepoints. It must be
///   fast and non-blocking, must not re-enter the concurrency runtime in ways
///   that could deadlock, and -- because subtree tasks run concurrently -- must
///   be safe to call from several threads at once. Whatever it accumulates into
///   must be thread-safe.
///
/// - Note: If the observed scope's final slice proceeds directly to process
///   exit (for example, observing the task that `@main` runs on, whose last
///   slice ends by exiting rather than returning), that slice's
///   `stoppedRunning` is not delivered. `completed` still fires. Observe a task
///   that completes normally for exact per-slice accounting.
///
/// - Parameters:
///   - operation: The operation to observe.
///   - onEvent: Called for each scheduling-state transition of a task in the
///     observed subtree.
///   - isolation: The actor `operation` is isolated to.
@available(SwiftStdlib 6.5, *)
public func withTaskExecutionObservation<T>(
  operation: () async throws -> T,
  onEvent: @escaping @Sendable (ExecutingTaskInfo, TaskExecutionEvent) -> Void,
  isolation: isolated (any Actor)? = #isolation
) async rethrows -> T {
  let observation = _TaskExecutionObservationRecord(onEvent: onEvent)

  // The record is installed at +1; the run brackets retain it per-slice, and
  // `_stopTaskExecutionObservation` drops this installed reference. The local
  // `observation` keeps it alive for the `completed` event below.
  let recordPointer = unsafe Unmanaged.passRetained(observation).toOpaque()
  let previous = unsafe _startTaskExecutionObservation(recordPointer)
  defer {
    unsafe _stopTaskExecutionObservation(recordPointer, previous)
    observation.onEvent(ExecutingTaskInfo(id: _getCurrentTaskId()), .completed)
  }
  return try await operation()
}
