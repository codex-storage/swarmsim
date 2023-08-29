import std/options
import std/random
import std/hashes
import sequtils
import sugar

import ./types
import ./message
import ./protocol
import ./eventdrivenengine
import ../lib/multitable

export options
export multitable
export protocol
export eventdrivenengine
export Peer

type
  PeerLifecycleChange* = ref object of SchedulableEvent
    peer: Peer
    network: Network
    event: LifecycleEventType

method atScheduledTime*(self: PeerLifecycleChange,
    engine: EventDrivenEngine): void =

  let peer = self.peer
  let oldState = peer.up

  # XXX We're somewhat lax with state machine transitions and will allow
  # self-transitions...
  let newState = case self.event:
    of started, up:
      true
    of down:
      false

  peer.up = newState

  # ... but self-transitions do not get reported downstream.
  if oldState != newState:
    self.peer.protocols.values.toSeq.apply(p =>
        p.onPeerLifecycleChange(self.peer, self.event, self.network))

proc getProtocol*(self: Peer, id: string): Option[Protocol] =
  if self.protocols.hasKey(id):
    return self.protocols[id].some

  none(Protocol)

proc addProtocol*[T: Protocol](self: Peer, protocol: T): void =
  self.protocols[protocol.protocolId] = protocol

proc deliverForType(self: Peer, messageType: string, message: Message,
    engine: EventDrivenEngine, network: Network): void =
  self.dispatch.getOrDefault(messageType, @[]).apply(
    proc (p: Protocol): void = p.deliver(message, engine, network))

proc deliver*(self: Peer, message: Message, engine: EventDrivenEngine,
    network: Network): void =
  self.deliverForType(message.messageType, message, engine, network)
  self.deliverForType(Message.allMessages, message, engine, network)

proc scheduleLifecycleChange*(self: Peer, event: LifecycleEventType,
    network: Network, time: uint64): void =
  network.engine.schedule(PeerLifecycleChange(
    peer: self,
    network: network,
    event: event,
    time: time
  ))

proc startAt*(self: Peer, network: Network, time: uint64): void =
  self.scheduleLifecycleChange(started, network, time)

proc start*(self: Peer, network: Network): void =
  self.startAt(network, network.engine.currentTime)

proc initPeer*(self: Peer, protocols: seq[Protocol],
    peerId: Option[int] = none(int)): Peer =

  self.peerId = peerId.get(rand(high(int)))
  self.protocols = initTable[string, Protocol]()
  self.dispatch = MultiTable[string, Protocol].new()
  # XXX integer indexes or an enum would be better, but this is easier
  for protocol in protocols:
    let protocol = protocol # https://github.com/nim-lang/Nim/issues/16740

    self.protocols[protocol.protocolId] = protocol
    protocol.messageTypes.apply(proc (m: string): void =
      self.dispatch.add(m, protocol))

  self

proc hash*(self: Peer): Hash = self.peerId.hash

proc new*(
  T: type Peer,
  protocols: seq[Protocol],
  peerId: Option[int] = none(int),
): Peer =
  initPeer(Peer(), protocols, peerId)
