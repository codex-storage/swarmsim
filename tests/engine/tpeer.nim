import std/unittest
import std/sets

import swarmsim/engine/peer

suite "peer":
  test "should allow inclusion and membership tests on a HashSet":
    var peerSet = HashSet[Peer]()

    let p1 = Peer.new(protocols = @[], peerId = 1.some)
    let p2 = Peer.new(protocols = @[], peerId = 2.some)

    peerSet.incl(p1)

    check(peerSet.contains(p1))
    check(not peerSet.contains(p2))

    peerSet.excl(p1)

    check(not peerSet.contains(p1))
