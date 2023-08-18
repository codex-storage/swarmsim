import unittest

import std/times
import std/algorithm
import sequtils
import sugar

import pkg/swarmsim/engine/eventdrivenengine
import pkg/swarmsim/engine/peer
import pkg/swarmsim/engine/network
import pkg/swarmsim/codex/dhttracker
import pkg/swarmsim/timeutils

proc getPeerArray(tracker: Peer): seq[PeerDescriptor] =
  DHTTracker(
      tracker.getProtocol(DHTTracker.messageType).get()).peers

proc getPeerIdArray(tracker: Peer): seq[int] =
  getPeerArray(tracker).map(p => p.peerId)

proc announcePeer(network: Network, tracker: Peer, peerId: int,
    delay: uint64 = 0) =
  network.send(
    PeerAnnouncement(receiver: tracker,
      messageType: DHTTracker.messageType, peerId: peerId),
        delay.some).doAwait()

suite "tracker node":

  setup:
    let engine = EventDrivenEngine()

    let trackerPeer = Peer.new(
      protocols = @[
        Protocol DHTTracker.new(maxPeers = 5)
      ]
    )

    let network = Network.new(engine = engine)
    network.add(trackerPeer)

  test "should retain published descriptors":
    announcePeer(network, trackerPeer, 25)

    let peers = getPeerArray(trackerPeer)

    check(len(peers) == 1)
    check(peers[0].peerId == 25)

  test "should not include the same peer more than once":
    announcePeer(network, trackerPeer, 25)
    announcePeer(network, trackerPeer, 25)

    let peers = getPeerArray(trackerPeer)

    check(len(peers) == 1)
    check(peers[0].peerId == 25)


  test "should drop descriptors after expiry time":
    announcePeer(network, trackerPeer, 25)

    check(len(getPeerArray(trackerPeer)) == 1)
    engine.runUntil(DHTTracker.defaultExpiry + 1.dseconds)

    check(len(getPeerArray(trackerPeer)) == 0)

  test "should renew expiry time if peer republishes its record":
    announcePeer(network, trackerPeer, 25)

    check(len(getPeerArray(trackerPeer)) == 1)
    engine.runUntil(DHTTracker.defaultExpiry - 1.dseconds)

    announcePeer(network, trackerPeer, 25)

    engine.runUntil(DHTTracker.defaultExpiry + 15.dseconds)
    check(len(getPeerArray(trackerPeer)) == 1)

    engine.runUntil(2*DHTTracker.defaultExpiry + 1.dseconds)
    check(len(getPeerArray(trackerPeer)) == 0)

  test "should drop oldest peers when table is full":
    announcePeer(network, trackerPeer, 25, delay = 0)
    announcePeer(network, trackerPeer, 35, delay = 1)
    announcePeer(network, trackerPeer, 45, delay = 2)
    announcePeer(network, trackerPeer, 55, delay = 3)
    announcePeer(network, trackerPeer, 65, delay = 4)

    check(getPeerIdArray(trackerPeer).sorted == @[25, 35, 45, 55, 65])

    announcePeer(network, trackerPeer, 75, delay = 1)

    check(getPeerIdArray(trackerPeer).sorted == @[35, 45, 55, 65, 75])
