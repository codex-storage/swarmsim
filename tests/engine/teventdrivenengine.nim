import unittest
import sequtils
import sugar

import std/algorithm

import swarmsim/engine/schedulableevent
import swarmsim/engine/eventdrivenengine

type TestSchedulable = ref object of SchedulableEvent

method atScheduledTime(self: TestSchedulable, engine: EventDrivenEngine): void =
  discard

suite "event driven engine tests":

  test "should run schedulables at the right time":

    let times = @[1'u64, 10, 5]
    let schedulables = times.map(time => TestSchedulable(time: time))

    let engine = EventDrivenEngine()

    engine.scheduleAll(schedulables)

    for time in times.sorted:
      let result = engine.nextStep().get()
      check(result.time == engine.currentTime)

    check(engine.nextStep().isNone)

  test "should allow clients to wait until a scheduled event happens":
    let times = @[1'u64, 2, 3, 4, 5, 6, 7, 8]
    let schedulables = times.map(time => TestSchedulable(time: time))

    let engine = EventDrivenEngine()
    let handles = schedulables.map(schedulable =>
      engine.awaitableSchedule(schedulable))

    check(engine.currentTime == 0)

    handles[4].doAwait()
    check(engine.currentTime == 5)

    handles[7].doAwait()
    check(engine.currentTime == 8)

  test "should allow clients run until the desired simulation time":
    let times = @[50'u64, 100, 150]
    let schedulables = times.map(time => TestSchedulable(time: time))

    let engine = EventDrivenEngine()
    engine.scheduleAll(schedulables)

    engine.runUntil(80)

    check(engine.currentTime == 80)
    check(schedulables[0].completed)
    check(not schedulables[1].completed)

    engine.runUntil(110)

    check(engine.currentTime == 110)
    check(schedulables[1].completed)
    check(not schedulables[2].completed)

    engine.runUntil(200)
    check(engine.currentTime == 150)
    check(schedulables[2].completed)

  test "should not allow schedulables to be scheduled in the past":
    let e1 = TestSchedulable(time: 10)
    let e2 = TestSchedulable(time: 8)

    let engine = EventDrivenEngine()
    engine.schedule(e1)
    discard engine.nextStep()

    expect(Defect):
      engine.schedule(e2)

  test "should allow clients to cancel scheduled events":
    let e1 = TestSchedulable(time: 8)
    let e2 = TestSchedulable(time: 10)

    let engine = EventDrivenEngine()

    let e1Handle = engine.awaitableSchedule(e1)
    let e2Handle = engine.awaitableSchedule(e2)

    e1Handle.schedulable.cancel()
    e2Handle.doAwait()

    check(engine.currentTime == 10)

  test "should run to completion":
    let times = @[1'u64, 2, 3, 4, 5, 6, 7, 8]

    let engine = EventDrivenEngine()

    let handles = times.map(time =>
      engine.awaitableSchedule(TestSchedulable(time: time)))

    check(handles.allIt(it.schedulable.completed) == false)

    engine.run()

    check(engine.currentTime == 8)
    check(handles.allIt(it.schedulable.completed) == true)

  test "should allow clients to run until a predicate is satistified":
    let times = @[50'u64, 100, 150, 200]

    let engine = EventDrivenEngine()

    times.apply((time: uint64) => engine.schedule(TestSchedulable(time: time)))

    const stopIndex = 3
    var index = 0

    check(engine.runUntil(
      proc (engine: EventDrivenEngine, schedulable: SchedulableEvent): bool =
        index += 1
        index == stopIndex
    ))

    check(index == stopIndex)
    check(engine.currentTime == times[stopIndex - 1])
