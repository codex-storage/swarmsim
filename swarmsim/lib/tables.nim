import std/tables

export tables

template getDefault*[K, V](self: var Table[K, V], key: K, alias,
    body: untyped): void =
  ## An optimized template for getting a value from a table with a default fallback
  ## that gets inserted in the table as the key is accessed. This is essentially
  ## syntactic sugar on top of Table.withValue.
  ##
  runnableExamples:
    var table: Table[string, int] = initTable[string, int]()

    table.getDefault("hello", c):
      # like withValue, c is a pointer.
      c[] += 1

    table.getDefault("hello", c):
      # like withValue, c is a pointer.
      c[] += 1

    echo table["hello"] # 2

  self.withValue(key, v):
    var alias {.inject.} = v
    body
  do:
    var newVal = V.default()
    var alias {.inject.} = addr newVal
    body
    self[key] = alias[]
