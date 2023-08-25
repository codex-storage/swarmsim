import swarmsim/engine/types
import swarmsim/engine/peer
import swarmsim/engine/protocol
import swarmsim/engine/network

type
  Inbox* = ref object of Protocol
    protocolId*: string
    messages*: seq[Message]

method deliver*(
  self: Inbox,
  message: Message,
  engine: EventDrivenEngine,
  network: Network
) =
  self.messages.add(message)

method `protocolId`*(self: Inbox): string = self.protocolId

export Message
export peer
export protocol
export network
