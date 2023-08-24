import std/tables

type MultiTable[K, V] = Table[K, seq[V]]

proc new*[K, V](T: type MultiTable[K, V]): MultiTable[K, V] =
  initTable[K, seq[V]]()

proc add*[K, V](self: var MultiTable[K, V], key: K, value: V) =
  discard self.hasKeyOrPut(key, @[])
  self[key].add(value)

proc remove*[K, V](self: var MultiTable[K, V], key: K, value: V) =
  if not self.hasKey(key):
    return

  var values = self[key]
  let index = values.find(value)
  if index <= 0:
    return

  values.delete(index)
  if values.len == 0:
    self.del(key)
  else:
    self[key] = values

export MultiTable
export tables
