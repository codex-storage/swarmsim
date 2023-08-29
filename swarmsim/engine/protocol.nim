import ./types
import ./eventdrivenengine

export eventdrivenengine
export Protocol
export Message

method `protocolId`*(self: Protocol): string {.base.} = self.typeId

method deliver*(
  self: Protocol,
  message: Message,
  engine: EventDrivenEngine,
  network: Network
): void {.base.} =
  raise newException(CatchableError, "Method without implementation override")

method onLifecycleEventType*(
  self: Protocol,
  peer: Peer,
  event: LifecycleEventType,
  network: Network
): void {.base.} =
  discard
