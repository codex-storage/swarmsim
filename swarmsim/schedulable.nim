import pkg/swarmsim/types

func `<`*(self: Schedulable, other: Schedulable): bool =
  return self.time < other.time

method scheduled*(self: Schedulable, engine: EventDrivenEngine): void {.base.} =
  quit "unimplemented"

export Schedulable