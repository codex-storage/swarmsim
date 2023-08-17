import unittest

import pkg/swarmsim/engine/schedulableevent

suite "schedulable event":
  test "should be ordered by time":
    let e1 = SchedulableEvent(time: 1)
    let e2 = SchedulableEvent(time: 3)

    check(e1 < e2)
    check(not (e2 < e1))
