import ./types
import ./eventdrivenengine

export eventdrivenengine
export Protocol
export Message

method uncheckedDeliver(
  self: Protocol,
  message: Message,
  engine: EventDrivenEngine,
  network: Network
): void {.base.} =
  raise newException(CatchableError, "Method without implementation override")

proc deliver*(self: Protocol, message: Message, engine: EventDrivenEngine,
    network: Network): void =
  assert(self.messageType == message.messageType)
  self.uncheckedDeliver(message, engine, network)
