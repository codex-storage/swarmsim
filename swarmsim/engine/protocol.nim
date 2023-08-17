import ./types

method uncheckedDeliver(self: Protocol, message: Message): void {.base.} =
  raise newException(CatchableError, "Method without implementation override")

proc deliver*(self: Protocol, message: Message): void =
  assert(self.messageType == message.messageType)
  self.uncheckedDeliver(message)

export Protocol
