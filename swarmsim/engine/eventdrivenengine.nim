import std/options
import std/strformat
import std/times

import ./types
import ./schedulableevent

export options
export times
export EventDrivenEngine

type
  AwaitableHandle* = object of RootObj
    schedulable*: SchedulableEvent
    engine: EventDrivenEngine

proc currentTime*(self: EventDrivenEngine): uint64 {.inline.} = self.currentTime

proc schedule*(self: EventDrivenEngine, schedulable: SchedulableEvent): void =
  if schedulable.time < self.currentTime:
    raise (ref Defect)(
      msg: "Cannot schedule an event in the past " &
        fmt"({schedulable.time}) < ({self.currentTime})")
  self.queue.push(schedulable)

proc awaitableSchedule*(self: EventDrivenEngine,
    schedulable: SchedulableEvent): AwaitableHandle =
  self.schedule(schedulable)
  AwaitableHandle(schedulable: schedulable, engine: self)

proc scheduleAll*[T: SchedulableEvent](self: EventDrivenEngine,
    schedulables: seq[T]): void =
  for schedulable in schedulables:
    self.schedule(schedulable)

proc stepUntil(self: EventDrivenEngine,
    until: Option[uint64] = none(uint64)): Option[SchedulableEvent] =

  while len(self.queue) > 0:
    if until.isSome and self.queue[0].time > until.get:
      self.currentTime = until.get
      return none(SchedulableEvent)

    let schedulable = self.queue.pop()
    self.currentTime = schedulable.time

    if not schedulable.cancelled:
      schedulable.atScheduledTime(engine = self)
      schedulable.completed = true

      return some(schedulable)

  return none(SchedulableEvent)

proc nextStep*(self: EventDrivenEngine): Option[SchedulableEvent] =
  self.stepUntil()

proc runUntil*(self: EventDrivenEngine, until: uint64): void =
  while self.stepUntil(until.some).isSome and self.currentTime <= until:
    discard

proc runUntil*(self: EventDrivenEngine, until: Duration): void =
  self.runUntil(uint64(until.inSeconds()))

proc run*(self: EventDrivenEngine): void =
  self.runUntil(high(uint64))

proc doAwait*(self: AwaitableHandle): void =
  self.engine.runUntil(self.schedulable.time)
