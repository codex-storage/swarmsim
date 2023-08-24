import swarmsim/engine/types
import swarmsim/engine/peer
import swarmsim/engine/protocol
import swarmsim/engine/network

type
  Inbox* = ref object of Protocol
    messages*: seq[Message]

method deliver*(
  self: Inbox,
  message: Message,
  engine: EventDrivenEngine,
  network: Network
) =
  self.messages.add(message)

export Message
export peer
export protocol
export network
