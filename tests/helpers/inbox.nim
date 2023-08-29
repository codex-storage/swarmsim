import swarmsim/engine/types
import swarmsim/engine/peer
import swarmsim/engine/protocol
import swarmsim/engine/network
import swarmsim/lib/withtypeid

withTypeId:
  type
    Inbox* = ref object of Protocol
      protocolId*: string
      messages*: seq[Message]
      events*: seq[LifecycleEvent]

    LifecycleEvent* = ref object of RootObj
      event*: LifecycleEventType
      time*: uint64

method deliver*(
  self: Inbox,
  message: Message,
  engine: EventDrivenEngine,
  network: Network
) =
  self.messages.add(message)

method `protocolId`*(self: Inbox): string = self.protocolId

method onLifecycleEventType*(
  self: Inbox,
  peer: Peer,
  event: LifecycleEventType,
  network: Network
) =
  self.events.add(LifecycleEvent(event: event, time: network.engine.currentTime))

export Message
export LifecycleEvent
export peer
export protocol
export network
