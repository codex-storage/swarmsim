import unittest

import std/intsets

import swarmsim/engine
import swarmsim/codex/blockexchange

import ../helpers/testpeer

suite "block exchange":

  test "should respond to want-block message with a list of the blocks it has":
    let engine = EventDrivenEngine()
    let network = Network(engine: engine)
    let sender = TestPeer.new(network)

    let bex = BlockExchangeProtocol.new()

    let file = Manifest(cid: "QmHash", nBlocks: 4)
    bex.store.newFile(file)
    bex.store.storeBlocks(cid = "QmHash", blocks = @[0, 1, 2, 4])

    let peer = Peer.new(
      peerId = 1.some,
      protocols = @[Protocol bex]
    )

    let message = WantHave(
      sender: (Peer sender).some,
      receiver: peer,
      cid: file.cid,
      wants: toIntSet([0, 1, 3, 4])
    )

    discard sender.send(message)

    engine.run()

    check(len(sender.inbox.messages) == 1)

    let response = Have(sender.inbox.messages[0])

    check(response.haves == toIntSet([0, 1, 4]))
