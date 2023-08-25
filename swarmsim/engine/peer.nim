import std/options
import std/random
import std/hashes
import sequtils

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
