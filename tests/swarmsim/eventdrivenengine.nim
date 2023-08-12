import unittest
import sequtils
import sugar

import std/algorithm

import pkg/swarmsim/schedulableevent
import pkg/swarmsim/eventdrivenengine

type
  SimpleSchedulable = ref object of SchedulableEvent
    scheduledAt: uint64

method atScheduledTime(schedulable: SimpleSchedulable, engine: EventDrivenEngine) =
  schedulable.scheduledAt = engine.current_time

suite "event driven engine tests":

  test "should run schedulables at the right time":

    let times = @[1, 10, 5].map(time => uint64(time))
    let schedulables = times.map(time => SimpleSchedulable(time: time))

    let engine = EventDrivenEngine()

    engine.scheduleAll(schedulables)

    for time in times.sorted:
      let result = engine.nextStep().get()
      check(result.time == time)

    check(engine.nextStep().isNone)

    for schedulable in schedulables:
      check(schedulable.scheduledAt == schedulable.time)
