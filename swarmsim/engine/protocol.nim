import ./types
import ./message
import ./network
import ./eventdrivenengine

export message
export network
export eventdrivenengine
export Protocol

method uncheckedDeliver(
  self: Protocol,
  message: Message,
  engine: EventDrivenEngine,
  network: Network
): void {.base.} =
  raise newException(CatchableError, "Method without implementation override")

proc deliver*(self: Protocol, message: Message, engine: EventDrivenEngine, network: Network): void =
  assert(self.messageType == message.messageType)
  self.uncheckedDeliver(message, engine, network)
