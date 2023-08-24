import unittest

import swarmsim/engine/message
import swarmsim/engine/eventdrivenengine
import swarmsim/engine/network
import swarmsim/engine/peer
import swarmsim/engine/protocol

import ../helpers/inbox

suite "network":
  test "should dispatch message to the correct peer":

    let engine = EventDrivenEngine()

    let i1 = Inbox(id: "inbox", messageTypes: @["m"])
    let i2 = Inbox(id: "inbox", messageTypes: @["m"])

    let p1 = Peer.new(protocols = @[Protocol i1])
    let p2 = Peer.new(protocols = @[Protocol i2])

    let network = Network.new(engine = engine, defaultLinkDelay = 20)

    network.add(p1)
    network.add(p2)

    let m1: Message = FreelyTypedMessage(receiver: p1, messageType: "m")
    let m2: Message = FreelyTypedMessage(receiver: p2, messageType: "m")

    let message2handle = network.send(m2, linkDelay = uint64(10).some)
    let message1handle = network.send(m1, linkDelay = uint64(5).some)

    let noMessages: seq[Message] = @[]

    check(i1.messages == noMessages)
    check(i2.messages == noMessages)

    message1Handle.doAwait()

    check(i1.messages == @[m1])
    check(i2.messages == noMessages)

    message2Handle.doAwait()

    check(i1.messages == @[m1])
    check(i2.messages == @[m2])
