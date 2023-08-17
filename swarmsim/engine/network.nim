import std/options
import std/sets

import ./types
import ./peer
import ./eventdrivenengine

export options
export sets
export peer
export eventdrivenengine
export Network

type
  ScheduledMessage = ref object of SchedulableEvent
    message: Message

proc new*(
  T: type Network,
  engine: EventDrivenEngine,
  defaultLinkDelay: uint64 = 0
): T =
  return Network(
    engine: engine,
    defaultLinkDelay: defaultLinkDelay,
    peers: HashSet[Peer]()
  )

proc add*(self: Network, peer: Peer): void =
  # TODO: this can be very slow if the array keeps being resized, but for
  #   now I won't care much.
  self.peers.incl(peer)

proc remove*(self: Network, peer: Peer) =
  self.peers.excl(peer)

proc send*(self: Network, message: Message,
  linkDelay: Option[uint64] = none(uint64)): AwaitableHandle =

  let delay = linkDelay.get(self.defaultLinkDelay)

  self.engine.awaitableSchedule(
    ScheduledMessage(
      time: self.engine.current_time + delay,
      message: message
    )
  )

method atScheduledTime*(self: ScheduledMessage, engine: EventDrivenEngine) =
  self.message.receiver.deliver(self.message)