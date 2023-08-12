import pkg/swarmsim/types

func `<`*(self: SchedulableEvent, other: SchedulableEvent): bool =
  return self.time < other.time

method atScheduledTime*(self: SchedulableEvent, engine: EventDrivenEngine): void {.base.} =
  ## Callback invoked by the event engine indicating that this event is due for execution.
  ##
  quit "unimplemented"

export SchedulableEvent
