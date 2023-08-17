import std/options
import std/strformat

import ./types
import ./schedulableevent

export options
export EventDrivenEngine

type
  AwaitableHandle* = object of RootObj
    schedulable: SchedulableEvent
    engine: EventDrivenEngine

proc current_time*(self: EventDrivenEngine): uint64 {.inline.} = self.current_time

proc schedule*(self: EventDrivenEngine, schedulable: SchedulableEvent): void =
  if schedulable.time < self.current_time:
    raise (ref Defect)(
      msg: fmt"Cannot schedule an event in the past ({schedulable.time}) < ({self.current_time})")
  self.queue.push(schedulable)

proc awaitableSchedule*(self: EventDrivenEngine, schedulable: SchedulableEvent): AwaitableHandle =
  self.schedule(schedulable)
  AwaitableHandle(schedulable: schedulable, engine: self)

proc scheduleAll*[T: SchedulableEvent](self: EventDrivenEngine, schedulables: seq[T]): void =
  for schedulable in schedulables:
    self.schedule(schedulable)

proc nextStep*(self: EventDrivenEngine): Option[SchedulableEvent] =
  if len(self.queue) == 0:
    return none(SchedulableEvent)

  let schedulable = self.queue.pop()
  self.current_time = schedulable.time
  schedulable.atScheduledTime(engine = self)

  some(schedulable)

proc runUntil*(self: EventDrivenEngine, until: uint64): void =
  while self.nextStep().isSome and self.current_time < until:
    discard

proc run*(self: EventDrivenEngine): void =
  self.runUntil(high(uint64))

proc doAwait*(self: AwaitableHandle): void =
  self.engine.runUntil(self.schedulable.time)
