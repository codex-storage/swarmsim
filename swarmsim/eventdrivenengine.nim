import std/options

import pkg/swarmsim/types
import pkg/swarmsim/schedulable

proc current_time*(self: EventDrivenEngine): uint64 {.inline.} = self.current_time

proc schedule*(self: EventDrivenEngine, schedulable: Schedulable): EventDrivenEngine =
  self.queue.push(schedulable)
  self

proc scheduleAll*[T: Schedulable](self: EventDrivenEngine, schedulables: seq[T]): void =
  for schedulable in schedulables:
    discard self.schedule(schedulable)

proc nextStep*(self: EventDrivenEngine): Option[Schedulable] =
  if len(self.queue) == 0:
    return none(Schedulable)

  let schedulable = self.queue.pop()
  self.current_time = schedulable.time
  schedulable.scheduled(engine = self)

  some(schedulable)

proc run*(self: EventDrivenEngine): void =
  while self.nextStep().isSome:
    discard

export EventDrivenEngine
export options
