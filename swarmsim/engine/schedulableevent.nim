import ./types

export SchedulableEvent

func `<`*(self: SchedulableEvent, other: SchedulableEvent): bool =
  return self.time < other.time

proc cancel*(self: SchedulableEvent) =
  ## Cancels this event.
  ##
  self.cancelled = true

method atScheduledTime*(self: SchedulableEvent,
    engine: EventDrivenEngine): void {.base.} =
  ## Callback invoked by the event engine indicating that this event is due
  ## for execution.
  ##
  raise newException(CatchableError, "Method without implementation override")
