import unittest

import swarmsim/lib/tables

suite "tables":
  test "should create a default value and allow modification":
    var table: Table[string, int]

    table.getDefault("hello", c): c[] += 1

    table.getDefault("hello", c): c[] += 1

    check(table["hello"] == 2)

