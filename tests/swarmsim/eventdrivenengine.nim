import unittest
import sequtils
import sugar

import std/algorithm

import pkg/swarmsim/schedulableevent
import pkg/swarmsim/eventdrivenengine

suite "event driven engine tests":

  test "should run schedulables at the right time":

    let times = @[1, 10, 5].map(time => uint64(time))
    let schedulables = times.map(time => SchedulableEvent(time: time))

    let engine = EventDrivenEngine()

    engine.scheduleAll(schedulables)

    for time in times.sorted:
      let result = engine.nextStep().get()
      check(result.time == engine.current_time)

    check(engine.nextStep().isNone)
