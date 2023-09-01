import std/options
import std/strformat
import std/times
import sugar

import ./types
import ./schedulableevent

export options
export times
export EventDrivenEngine

type
  ScheduledEvent* = object of RootObj
    schedulable*: SchedulableEvent
    engine: EventDrivenEngine

  Predicate* = (EventDrivenEngine, SchedulableEvent) -> bool

proc currentTime*(self: EventDrivenEngine): uint64 {.inline.} = self.currentTime

proc schedule*(self: EventDrivenEngine, schedulable: SchedulableEvent): void =
  ## Schedules a `SchedulableEvent` for execution.
  if schedulable.time < self.currentTime:
    raise (ref Defect)(
      msg: "Cannot schedule an event in the past " &
        fmt"({schedulable.time}) < ({self.currentTime})")
  self.queue.push(schedulable)

proc awaitableSchedule*(self: EventDrivenEngine,
    schedulable: SchedulableEvent): ScheduledEvent =
  self.schedule(schedulable)
  ScheduledEvent(schedulable: schedulable, engine: self)

proc scheduleAll*[T: SchedulableEvent](self: EventDrivenEngine,
    schedulables: seq[T]): void =
  schedulables.apply((s: T) => self.schedule(s))

proc stepUntil(self: EventDrivenEngine,
    timeout: Option[uint64] = none(uint64)): Option[SchedulableEvent] =

  while len(self.queue) > 0:
    # This allows us to halt execution even when in-between events if
    # a time predicate is satistifed.
    if timeout.isSome and self.queue[0].time > timeout.get:
      self.currentTime = timeout.get
      return none(SchedulableEvent)

    let schedulable = self.queue.pop()
    self.currentTime = schedulable.time

    if not schedulable.cancelled:
      schedulable.atScheduledTime(engine = self)
      schedulable.completed = true

      return some(schedulable)

  return none(SchedulableEvent)

proc nextStep*(self: EventDrivenEngine): Option[SchedulableEvent] =
  ## Runs the engine until the next event, returning none(SchedulableEvent)
  ## if no there are no events left.
  self.stepUntil()

proc runUntil*(self: EventDrivenEngine, timeout: uint64): void =
  ## Runs the engine until the specified simulation time. Can be used to
  ## implement awaits with timeouts, and for testing.
  while self.stepUntil(timeout.some).isSome and self.currentTime <= timeout:
    discard

proc runUntil*(self: EventDrivenEngine, predicate: Predicate,
    timeout: Option[uint64] = none(uint64)): bool =
  ## Runs the engine until a `Predicate` is true, or a specified time is
  ## reached -- whichever happens first.
  while true:
    let schedulable = self.stepUntil(timeout)
    if schedulable.isNone:
      return false

    if predicate(self, schedulable.get):
      return true

proc runUntil*(self: EventDrivenEngine, until: Duration): void =
  self.runUntil(uint64(until.inSeconds()))

proc run*(self: EventDrivenEngine): void =
  self.runUntil(high(uint64))

proc doAwait*(self: ScheduledEvent): void =
  self.engine.runUntil(self.schedulable.time)
