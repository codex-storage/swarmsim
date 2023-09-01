import unittest
import sugar

import std/intsets
import std/sequtils

import swarmsim/engine
import swarmsim/codex/blockexchange

import ../../helpers/testpeer

proc newBexPeer(manifest: Manifest, peerId: int, has: seq[int] = @[]): Peer =
  var bex = BlockExchangeProtocol.new()

  discard bex.newSession(manifest)
  bex.session(manifest).storeBlocks(blocks = has)

  Peer.new(
    peerId = peerId.some,
    protocols = @[Protocol bex]
  )

suite "block exchange":

  setup:
    let engine = EventDrivenEngine()
    let network = Network(engine: engine)

  test "should bootstrap block knowledge from newly added neighbors":

    let manifest = Manifest(cid: "QmHash", nBlocks: 10)

    let swarm = @[
      newBexPeer(manifest, 1, has = @[0, 1, 3, 5]),
      newBexPeer(manifest, 2, has = @[0, 2, 4, 6]),
      newBexPeer(manifest, 3, has = @[0, 1, 3, 5]),
      newBexPeer(manifest, 4, has = @[7, 8, 9]),
    ]

    let newcomer = newBexPeer(manifest, 5)

    var bex = BlockExchangeProtocol(
        newcomer.getProtocol(BlockExchangeProtocol.typeId).get)

    swarm.apply((neighbor: Peer) =>
      bex.neighborAdded(newcomer, neighbor, manifest, network))

    check(engine.runUntil(
      proc (engine: EventDrivenEngine, schedulable: SchedulableEvent): bool =
        len(bex.session(manifest).blockPeerMap) == 10))

    let blockPeerMap = bex.session(manifest).blockPeerMap

    check(blockPeerMap[0] == toIntSet([1, 2, 3]))
    check(blockPeerMap[1] == toIntSet([1, 3]))
    check(blockPeerMap[2] == toIntSet([2]))
    check(blockPeerMap[3] == toIntSet([1, 3]))
    check(blockPeerMap[4] == toIntSet([2]))
    check(blockPeerMap[5] == toIntSet([1, 3]))
    check(blockPeerMap[6] == toIntSet([2]))
    check(blockPeerMap[7] == toIntSet([4]))
    check(blockPeerMap[8] == toIntSet([4]))
    check(blockPeerMap[9] == toIntSet([4]))
