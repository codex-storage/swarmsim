import std/tables
import std/options
import std/random

import ./types
import ./protocol

export options
export tables
export protocol
export Peer

proc getProtocol*(self: Peer, protocolId: string): Option[Protocol] =
  if self.protocols.hasKey(protocolId):
    return self.protocols[protocolId].some

  none(Protocol)

proc deliver*(self: Peer, message: Message): void =
  self.getProtocol(message.messageType).map(
    proc (p: Protocol): void = p.deliver(message))

proc initPeer(self: Peer, protocols: seq[Protocol]): Peer =
  # XXX integer indexes or an enum would be better, but this is easier
  for protocol in protocols:
    self.protocols[protocol.messageType] = protocol

  self

proc hash*(self: Peer): int = self.peerId

proc new*(
  T: type Peer,
  protocols: seq[Protocol],
  peerId: Option[int] = none(int),
): Peer =
  # XXX I can't have put this in the init proc as that would mean allowing public
  #   write access to every field in Peer. Not sure how to solve this in nim.
  let peerId = peerId.get(rand(high(int)))
  initPeer(Peer(protocols: initTable[string, Protocol](), peerId: peerId), protocols)
