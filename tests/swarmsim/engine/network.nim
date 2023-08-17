import unittest

import pkg/swarmsim/engine/eventdrivenengine
import pkg/swarmsim/engine/network
import pkg/swarmsim/engine/peer
import pkg/swarmsim/engine/message
import pkg/swarmsim/engine/protocol

type
  FakeProtocol = ref object of Protocol
    received: bool

method uncheckedDeliver(self: FakeProtocol, message: Message,
    engine: EventDrivenEngine, network: Network) =
  self.received = true

proc getFakeProtocol(peer: Peer, protocolId: string): FakeProtocol =
  let protocol = peer.getProtocol(protocolId)
  check(protocol.isSome)
  return FakeProtocol(protocol.get())

suite "network":
  test "should dispatch message to the correct protocol within a peer":
    let engine = EventDrivenEngine()

    let peer = Peer.new(
      protocols = @[
        Protocol FakeProtocol(messageType: "protocol1", received: false),
        FakeProtocol(messageType: "protocol2", received: false)
      ]
    )
    let network = Network.new(engine = engine, defaultLinkDelay = 20)

    network.add(peer)

    let m1 = Message.new(receiver = peer, messageType = "protocol1")
    let m2 = Message.new(receiver = peer, messageType = "protocol2")

    let message2handle = network.send(m2, linkDelay = uint64(10).some)
    let message1handle = network.send(m1, linkDelay = uint64(5).some)

    check(not peer.getFakeProtocol("protocol1").received)
    check(not peer.getFakeProtocol("protocol2").received)

    message1Handle.doAwait()

    check(peer.getFakeProtocol("protocol1").received)
    check(not peer.getFakeProtocol("protocol2").received)

    message2Handle.doAwait()

    check(peer.getFakeProtocol("protocol1").received)
    check(peer.getFakeProtocol("protocol2").received)

