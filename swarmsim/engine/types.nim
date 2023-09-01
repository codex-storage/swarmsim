import std/heapqueue
import std/tables
import std/options
import std/random

import ../lib/withtypeid
import ../lib/multitable

export heapqueue
export option
export random
export withtypeid

type
  SchedulableEvent* = ref object of RootObj
    ## A `SchedulableEvent` is an event that can be scheduled for execution
    ## in an `EventDrivenEngine` at a well-defined point in simuliation time.
    ##
    time*: uint64
    cancelled*: bool
    completed*: bool

type
  EventDrivenEngine* = ref object of RootObj
    ## An `EventDrivenEngine` is a simple simulation engine that executes
    ## events in the order of their scheduled time.
    ##
    currentTime*: uint64
    queue*: HeapQueue[SchedulableEvent]

type
  Protocol* = ref object of RootObj
    ## A `Protocol` defines a P2P protocol. It handles messages meant for it,
    ## keeps internal state, and may expose services to other `Protocol`s within
    ## the same `Peer`.
    messageTypes*: seq[string]

  LifecycleEventType* = enum
    started
    up
    down

  Peer* = ref object of RootObj
    ## A `Peer` in our `Network` which runs `Protocols`. Together with other
    ## `Peer`s, forms a P2P network.
    peerId*: int
    up*: bool = false

    # FIXME these are expensive data structures to have per-peer, and can
    #   significantly affect memory scalability. If this turns out to be the
    #   memory bottleneck, we can fliweight those by using fixed peer types.
    protocols*: Table[string, Protocol]
    dispatch*: MultiTable[string, Protocol]

type
  Message* = ref object of RootObj
    ## A `Message` is a piece of data that is sent over the network. Its meaning
    ## is typically protocol-specific.
    sender*: Option[Peer] = none(Peer)
    receiver*: Peer

type
  Network* = ref object of RootObj
    ## A `Network` allows `Peer`s to send `Message`s to one another.
    ##
    engine*: EventDrivenEngine
    defaultLinkDelay*: uint64

