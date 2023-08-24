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

proc addProtocol*(self: Peer, protocol: Protocol): void =
  self.protocols[protocol.id] = protocol

proc deliver*(self: Peer, message: Message, engine: EventDrivenEngine,
    network: Network): void =
  self.dispatch.getOrDefault(message.messageType, @[]).apply(
    proc (p: Protocol): void = p.deliver(message, engine, network))

proc initPeer(self: Peer, protocols: seq[Protocol]): Peer =
  # XXX integer indexes or an enum would be better, but this is easier
  for protocol in protocols:
    let protocol = protocol # https://github.com/nim-lang/Nim/issues/16740

    self.protocols[protocol.id] = protocol
    protocol.messageTypes.apply(proc (m: string): void =
      self.dispatch.add(m, protocol))

  self

proc hash*(self: Peer): Hash = self.peerId.hash

proc new*(
  T: type Peer,
  protocols: seq[Protocol],
  peerId: Option[int] = none(int),
): Peer =
  # XXX I can't have put this in the init proc as that would mean allowing public
  #   write access to every field in Peer. Not sure how to solve this in nim.
  let peerId = peerId.get(rand(high(int)))
  initPeer(Peer(
    protocols: initTable[string, Protocol](),
    peerId: peerId,
    dispatch: MultiTable[string, Protocol].new()
    ), protocols)
