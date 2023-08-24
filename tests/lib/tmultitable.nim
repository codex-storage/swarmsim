import std/unittest

import pkg/swarmsim/lib/multitable

suite "multitable":
  test "should allow adding multiple values per key":
    var table = MultiTable[string, int].new()

    table.add("key", 1)
    table.add("key", 2)
    table.add("key", 3)

    check(table["key"] == [1, 2, 3])

  test "should allow removal of values bound to a key":
    var table = MultiTable[string, int].new()

    table.add("key", 1)
    table.add("key", 2)
    table.add("key", 3)

    table.remove("key", 2)

    check(table["key"] == [1, 3])
