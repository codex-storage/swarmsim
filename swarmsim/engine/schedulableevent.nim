import ./types

func `<`*(self: SchedulableEvent, other: SchedulableEvent): bool =
  return self.time < other.time

proc `time=`*(self: SchedulableEvent, value: float): void {.error: "Cannot assign to `time` property of `SchedulableEvent`.".}

method atScheduledTime*(self: SchedulableEvent, engine: EventDrivenEngine): void {.base.} =
  ## Callback invoked by the event engine indicating that this event is due for execution. By
  ## default, it does nothing.
  ##
  discard

export SchedulableEvent
