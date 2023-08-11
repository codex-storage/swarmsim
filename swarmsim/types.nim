import std/heapqueue

type
  Schedulable* = ref object of RootObj
    ## A `Schedulable` is something that can be scheduled for execution in an
    ## `EventDrivenEngine`.
    time*: uint64

type
  EventDrivenEngine* = ref object of RootObj
    current_time*: uint64
    queue*: HeapQueue[Schedulable]

export heapqueue
