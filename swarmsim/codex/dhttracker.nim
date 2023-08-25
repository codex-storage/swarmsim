import std/times
import std/options
import std/algorithm
import std/tables
import std/sequtils

import ../engine
import ../engine/message

export protocol
export options

type
  PeerDescriptor* = ref object of RootObj
    peerId*: int
    lastSeen*: uint64
    peerExpiration: ScheduledEvent

type ArrayShuffler = proc (arr: var seq[PeerDescriptor]): void

withTypeId:
  type
    DHTTracker* = ref object of Protocol
      peerExpiration*: Duration
      maxPeers*: uint
      peers: OrderedTable[int, PeerDescriptor]
      shuffler: ArrayShuffler

    PeerAnnouncement* = ref object of Message
      peerId*: int

    SampleSwarm* = ref object of Message
      numPeers: uint

type
  ExpirationTimer* = ref object of SchedulableEvent
    peerId*: int
    tracker: DHTTracker

let RandomShuffler = proc (arr: var seq[PeerDescriptor]) =
  discard arr.nextPermutation()

proc defaultExpiry*(T: type DHTTracker): Duration = 15.dminutes

proc new*(
  T: type DHTTracker,
  maxPeers: uint,
  shuffler: ArrayShuffler = RandomShuffler,
  peerExpiration: Duration = DHTTracker.defaultExpiry,
): DHTTracker =
  DHTTracker(
    # This should in general be safe as those are always positive.
    peerExpiration: peerExpiration,
    maxPeers: maxPeers,
    shuffler: shuffler,
    peers: initOrderedTable[int, PeerDescriptor](),
    messageTypes: @[PeerAnnouncement.typeId, SampleSwarm.typeId]
  )

proc peers*(self: DHTTracker): seq[PeerDescriptor] = self.peers.values.toSeq()

proc cancelExpiryTimer(self: DHTTracker, peerId: int) =
  self.peers[peerId].peerExpiration.schedulable.cancel()

proc createExpiryTimer(self: DHTTracker, peerId: int,
    engine: EventDrivenEngine): ScheduledEvent =
  let peerExpiration = ExpirationTimer(
    peerId: peerId,
    tracker: self,
    time: engine.currentTime + uint64(self.peerExpiration.inSeconds())
  )

  engine.awaitableSchedule(peerExpiration)

proc oldestInsertion(self: DHTTracker): int =
  # We maintain the invariant that the first element to have been inserted
  # must be the oldest. We can therefore return the first element in the
  # ordered table.
  for peerId in self.peers.keys:
    return peerId

proc removePeer(self: DHTTracker, peerId: int) =
  self.cancelExpiryTimer(peerId)
  self.peers.del(peerId)

proc addPeer(self: DHTTracker, message: PeerAnnouncement,
    engine: EventDrivenEngine) =

  let peerId = message.peerId

  if peerId in self.peers:
    # Makes sure that the most recently seen peer is always inserted last.
    self.removePeer(peerId)

  elif uint(len(self.peers)) == self.maxPeers:
    self.removePeer(self.oldestInsertion())

  self.peers[peerId] = PeerDescriptor(
    peerId: message.peerId,
    lastSeen: engine.currentTime,
    peerExpiration: self.createExpiryTimer(peerId, engine)
  )

method atScheduledTime*(self: ExpirationTimer, engine: EventDrivenEngine): void =
  self.tracker.peers.del(self.peerId)

proc sampleSwarm(self: DHTTracker, message: SampleSwarm, network: Network) =
  discard

method deliver*(self: DHTTracker, message: Message, engine: EventDrivenEngine,
    network: Network) =

  if message of PeerAnnouncement:
    self.addPeer(PeerAnnouncement(message), engine)
  elif message of SampleSwarm:
    self.sampleSwarm(SampleSwarm(message), network)
