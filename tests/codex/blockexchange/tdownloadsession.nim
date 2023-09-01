import unittest

import std/intsets
import options

import swarmsim/codex/blockexchange/downloadsession

suite "dowload session":
  setup:
    let manifest = Manifest(cid: "QmHash", nBlocks: 10)
    var session = DownloadSession(manifest: manifest)

  test "should allow known stored blocks to be queried":
    session.storeBlocks(@[0, 1, 5, 8])
    check(session.queryKnownBlocks() == toIntSet(@[0, 1, 5, 8]))

  test "should return queries on overlapping known blocks":
    session.storeBlocks(@[0, 1, 2, 3, 4, 5])
    check(session.queryKnownBlocks(@[0, 3, 8].some) == toIntSet(@[0, 3]))
    check(session.queryKnownBlocks(toIntSet(@[0, 3, 8]).some) ==
      toIntSet(@[0, 3]))

  test "should allow querying for peers that know about a block":
    session.storeBlockPeerMapping(peerId = 1, toIntSet(@[0, 1, 3, 4, 9]))
    session.storeBlockPeerMapping(peerId = 2, toIntSet(@[0, 1, 3, 5, 8]))
    session.storeBlockPeerMapping(peerId = 3, toIntSet(@[0, 7, 8]))

    check(session.peersForBlock(0) == toIntSet(@[1, 2, 3]))
    check(session.peersForBlock(1) == toIntSet(@[1, 2]))
    check(session.peersForBlock(2) == toIntSet(@[]))
    check(session.peersForBlock(3) == toIntSet(@[1, 2]))
    check(session.peersForBlock(4) == toIntSet(@[1]))
    check(session.peersForBlock(5) == toIntSet(@[2]))
    check(session.peersForBlock(7) == toIntSet(@[3]))
    check(session.peersForBlock(8) == toIntSet(@[2, 3]))
    check(session.peersForBlock(9) == toIntSet(@[1]))

