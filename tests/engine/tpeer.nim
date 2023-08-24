import unittest
import std/sets

import swarmsim/engine/eventdrivenengine
import swarmsim/engine/network
import swarmsim/engine/peer
import swarmsim/engine/message

import ../helpers/inbox

# We need this here as otherwise for some reason the nim compiler trips.
proc `$`*(m: Message): string = repr m

suite "peer":
  setup:
    let engine = EventDrivenEngine()
    let network = Network.new(engine = engine, defaultLinkDelay = 20)

  test "should allow inclusion and membership tests on a HashSet":
    var peerSet = HashSet[Peer]()

    let p1 = Peer.new(protocols = @[], peerId = 1.some)
    let p2 = Peer.new(protocols = @[], peerId = 2.some)

    peerSet.incl(p1)

    check(peerSet.contains(p1))
    check(not peerSet.contains(p2))

    peerSet.excl(p1)

    check(not peerSet.contains(p1))

  test "should dispatch message to correct protocol":
    let i1 = Inbox(id: "protocol1", messageTypes: @["m1"])
    let i2 = Inbox(id: "protocol2", messageTypes: @["m2"])

    let peer = Peer.new(protocols = @[Protocol i1, i2])

    let m1: Message = FreelyTypedMessage(receiver: peer, messageType: "m1")
    let m2: Message = FreelyTypedMessage(receiver: peer, messageType: "m2")

    peer.deliver(m1, engine, network)

    check(i1.messages == @[m1])
    check(i2.messages == seq[Message] @[])

    peer.deliver(m2, engine, network)

    check(i1.messages == @[m1])
    check(i2.messages == @[m2])

  test "should dispatch a message to multiple protocols if they are listening on the same message type":
    let i1 = Inbox(id: "protocol1", messageTypes: @["m1"])
    let i2 = Inbox(id: "protocol2", messageTypes: @["m1"])

    let peer = Peer.new(protocols = @[Protocol i1, i2])

    let m1: Message = FreelyTypedMessage(receiver: peer, messageType: "m1")

    peer.deliver(m1, engine, network)

    check(i1.messages == @[m1])
    check(i2.messages == @[m1])

  test "should allow protocol to listen on multiple message types":
    let i1 = Inbox(id: "protocol1", messageTypes: @["m1", "m2"])

    let peer = Peer.new(protocols = @[Protocol i1])

    let m1: Message = FreelyTypedMessage(receiver: peer, messageType: "m1")
    let m2: Message = FreelyTypedMessage(receiver: peer, messageType: "m2")
    let m3: Message = FreelyTypedMessage(receiver: peer, messageType: "m3")

    peer.deliver(m1, engine, network)
    peer.deliver(m2, engine, network)
    peer.deliver(m3, engine, network)

    check(i1.messages == @[m1, m2])


  test "should deliver all message types when listening to Message.allMessages":
    let i1 = Inbox(id: "protocol1", messageTypes: @[Message.allMessages])

    let peer = Peer.new(protocols = @[Protocol i1])

    let m1: Message = FreelyTypedMessage(receiver: peer, messageType: "m1")
    let m2: Message = FreelyTypedMessage(receiver: peer, messageType: "m2")
    let m3: Message = FreelyTypedMessage(receiver: peer, messageType: "m3")

    peer.deliver(m1, engine, network)
    peer.deliver(m2, engine, network)
    peer.deliver(m3, engine, network)

    check(i1.messages == @[m1, m2, m3])

