import std/options
import std/random

import swarmsim/engine
import swarmsim/engine/peer

import ./inbox

type TestPeer* = ref object of Peer
  network: Network

proc new*(
  t: typedesc[TestPeer],
  network: Network,
  peerId: Option[int] = none(int),
): TestPeer =
  let peer: TestPeer = TestPeer(network: network)
  discard peer.initPeer(protocols = @[Protocol Inbox()])
  peer

proc inbox*(peer: TestPeer): Inbox =
  Inbox peer.getProtocol(Inbox.protocolName).get()

proc send*(self: TestPeer, msg: Message): ScheduledEvent =
  msg.sender = Peer(self).some
  self.network.send(msg)
