import unittest
import sequtils
import sugar

import std/algorithm
import std/tables

import pkg/swarmsim/engine/schedulableevent
import pkg/swarmsim/engine/eventdrivenengine

suite "event driven engine tests":

  test "should run schedulables at the right time":

    let times = @[1, 10, 5].map(time => uint64(time))
    let schedulables = times.map(time => SchedulableEvent(time: time))

    let engine = EventDrivenEngine()

    engine.scheduleAll(schedulables)

    for time in times.sorted:
      let result = engine.nextStep().get()
      check(result.time == engine.currentTime)

    check(engine.nextStep().isNone)

  test "should allow clients to wait until a scheduled event happens":
    let times = @[1, 2, 3, 4, 5, 6, 7, 8]
    let schedulables = times.map(time => SchedulableEvent(time: uint64(time)))

    let engine = EventDrivenEngine()
    let handles = schedulables.map(schedulable => engine.awaitableSchedule(schedulable))

    check(engine.currentTime == 0)

    handles[4].doAwait()
    check(engine.currentTime == 5)

    handles[7].doAwait()
    check(engine.currentTime == 8)

  test "should not allow schedulables to be scheduled in the past":
    let e1 = SchedulableEvent(time: 10)
    let e2 = SchedulableEvent(time: 8)

    let engine = EventDrivenEngine()
    engine.schedule(e1)
    discard engine.nextStep()

    expect(Defect):
      engine.schedule(e2)

  test "should allow clients to cancel scheduled events":
    let e1 = SchedulableEvent(time: 8)
    let e2 = SchedulableEvent(time: 10)

    let engine = EventDrivenEngine()

    let e1Handle = engine.awaitableSchedule(e1)
    let e2Handle = engine.awaitableSchedule(e2)

    e1Handle.schedulable.cancel()
    e2Handle.doAwait()

    check(engine.currentTime == 10)





