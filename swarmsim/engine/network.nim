import std/options

import ./types
import ./peer
import ./eventdrivenengine

export options
export peer
export eventdrivenengine
export types

type
  MessageSend = ref object of SchedulableEvent
    network: Network
    message: Message

# TODO: use distributions (or trace resampling) instead of a constant for link delay
# TODO: model link capacity and implement downloads

proc new*(
  T: type Network,
  engine: EventDrivenEngine,
  defaultLinkDelay: uint64 = 0
): Network =
  Network(
    engine: engine,
    defaultLinkDelay: defaultLinkDelay
  )

proc send*(self: Network, message: Message,
  linkDelay: Option[uint64] = none(uint64)): ScheduledEvent =

  let delay = linkDelay.get(self.defaultLinkDelay)

  self.engine.awaitableSchedule(
    MessageSend(
      time: self.engine.currentTime + delay,
      message: message,
      network: self
    )
  )

method atScheduledTime*(self: MessageSend, engine: EventDrivenEngine) =
  self.message.receiver.deliver(self.message, engine, self.network)
