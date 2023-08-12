import std/heapqueue

type
  SchedulableEvent* = ref object of RootObj
    ## A `SchedulableEvent` is an event that can be scheduled for execution in an `EventDrivenEngine`
    ## at a well-defined point in simuliation time.
    ##
    time*: uint64

type
  EventDrivenEngine* = ref object of RootObj
    current_time*: uint64
    queue*: HeapQueue[SchedulableEvent]

export heapqueue
