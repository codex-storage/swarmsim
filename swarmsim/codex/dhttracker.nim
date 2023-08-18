import std/times
import std/options
import std/algorithm
import std/tables
import std/sequtils

import ../engine

export protocol
export options

type
  PeerDescriptor* = ref object of RootObj
    peerId*: int
    lastSeen*: uint64
    expirationTimer: AwaitableHandle

type ArrayShuffler = proc (arr: var seq[PeerDescriptor]): void

type
  DHTTracker* = ref object of Protocol
    expirationTimer*: Duration
    maxPeers*: uint
    peers: OrderedTable[int, PeerDescriptor]
    shuffler: ArrayShuffler

  PeerAnnouncement* = ref object of Message
    peerId*: int

  SampleSwarm* = ref object of Message
    numPeers: uint

  ExpirationTimer* = ref object of SchedulableEvent
    peerId*: int
    tracker: DHTTracker

let RandomShuffler = proc (arr: var seq[PeerDescriptor]) =
  discard arr.nextPermutation()

proc messageType*(T: type DHTTracker): string = "DHTTracker"

proc defaultExpiry*(T: type DHTTracker): Duration = 15.dminutes

proc new*(
  T: type DHTTracker,
  maxPeers: uint,
  shuffler: ArrayShuffler = RandomShuffler,
  expirationTimer: Duration = DHTTracker.defaultExpiry,
): DHTTracker =
  DHTTracker(
    # This should in general be safe as those are always positive.
    expirationTimer: expirationTimer,
    maxPeers: maxPeers,
    shuffler: shuffler,
    peers: initOrderedTable[int, PeerDescriptor](),
    messageType: DHTTracker.messageType
  )

proc peers*(self: DHTTracker): seq[PeerDescriptor] = self.peers.values.toSeq()

proc cancelExpiryTimer(self: DHTTracker, peerId: int) =
  self.peers[peerId].expirationTimer.schedulable.cancel()

proc createExpiryTimer(self: DHTTracker, peerId: int,
    engine: EventDrivenEngine): AwaitableHandle =
  let expirationTimer = ExpirationTimer(
    peerId: peerId,
    tracker: self,
    time: engine.currentTime + uint64(self.expirationTimer.inSeconds())
  )

  engine.awaitableSchedule(expirationTimer)

proc oldestInsertion(self: DHTTracker): int =
  # We maintain the invariant that the first element to have been inserted
  # must be the oldest. We can therefore return the first element in the
  # ordered table.
  for peerId in self.peers.keys:
    return peerId

proc addPeer(self: DHTTracker, message: PeerAnnouncement,
    engine: EventDrivenEngine) =

  let peerId = message.peerId

  if peerId in self.peers:
    self.cancelExpiryTimer(peerId)

  elif uint(len(self.peers)) == self.maxPeers:
    let oldest = self.oldestInsertion()
    self.cancelExpiryTimer(oldest)
    self.peers.del(oldest)

  self.peers[peerId] = PeerDescriptor(
    peerId: message.peerId,
    lastSeen: engine.currentTime,
    expirationTimer: self.createExpiryTimer(peerId, engine)
  )

method atScheduledTime*(self: ExpirationTimer, engine: EventDrivenEngine): void =
  self.tracker.peers.del(self.peerId)

proc sampleSwarm(self: DHTTracker, message: SampleSwarm, network: Network) =
  discard

method uncheckedDeliver*(self: DHTTracker, message: Message,
    engine: EventDrivenEngine, network: Network) =

  if message of PeerAnnouncement:
    self.addPeer(PeerAnnouncement(message), engine)
  elif message of SampleSwarm:
    self.sampleSwarm(SampleSwarm(message), network)
