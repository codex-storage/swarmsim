import typetraits

import ./types
import ./eventdrivenengine

export eventdrivenengine
export Protocol
export Message

method deliver*(self: Protocol, message: Message, engine: EventDrivenEngine,
    network: Network): void {.base.} =
  raise newException(CatchableError, "Method without implementation override")

proc protocolName*[T: Protocol](self: type T): string = name(T)
