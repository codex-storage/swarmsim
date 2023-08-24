import typetraits

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
  self.uncheckedDeliver(message, engine, network)

proc protocolName*[T: Protocol](self: type T): string = name(T)
