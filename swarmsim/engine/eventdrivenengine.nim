import std/options
import std/strformat

import ./types
import ./schedulableevent

export options
export EventDrivenEngine

type
  AwaitableHandle* = object of RootObj
    schedulable*: SchedulableEvent
    engine: EventDrivenEngine

proc currentTime*(self: EventDrivenEngine): uint64 {.inline.} = self.currentTime

proc schedule*(self: EventDrivenEngine, schedulable: SchedulableEvent): void =
  if schedulable.time < self.currentTime:
    raise (ref Defect)(
      msg: fmt"Cannot schedule an event in the past ({schedulable.time}) < ({self.currentTime})")
  self.queue.push(schedulable)

proc awaitableSchedule*(self: EventDrivenEngine, schedulable: SchedulableEvent): AwaitableHandle =
  self.schedule(schedulable)
  AwaitableHandle(schedulable: schedulable, engine: self)

proc scheduleAll*[T: SchedulableEvent](self: EventDrivenEngine, schedulables: seq[T]): void =
  for schedulable in schedulables:
    self.schedule(schedulable)

proc nextStep*(self: EventDrivenEngine): Option[SchedulableEvent] =

  while len(self.queue) > 0:
    let schedulable = self.queue.pop()
    self.currentTime = schedulable.time

    if not schedulable.cancelled:
      schedulable.atScheduledTime(engine = self)
      return some(schedulable)

  return none(SchedulableEvent)

proc runUntil*(self: EventDrivenEngine, until: uint64): void =
  while self.nextStep().isSome and self.currentTime < until:
    discard

proc run*(self: EventDrivenEngine): void =
  self.runUntil(high(uint64))

proc doAwait*(self: AwaitableHandle): void =
  self.engine.runUntil(self.schedulable.time)
