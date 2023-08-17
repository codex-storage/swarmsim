import std/heapqueue
import std/tables
import std/sets
import std/options

export heapqueue
export option

type
  SchedulableEvent* = ref object of RootObj
    ## A `SchedulableEvent` is an event that can be scheduled for execution in an `EventDrivenEngine`
    ## at a well-defined point in simuliation time.
    ##
    time*: uint64

type
  EventDrivenEngine* = ref object of RootObj
    ## An `EventDrivenEngine` is a simple simulation engine that executes events in the order of their
    ## scheduled time.
    ##
    current_time*: uint64
    queue*: HeapQueue[SchedulableEvent]

type
  Protocol* = ref object of RootObj
    ## A `Protocol` defines a P2P protocol. It handles messages meant for it, keeps internal state,
    ## and may expose services to other `Protocol`s within the same `Peer`.
    messageType*: string ## "Type" of the message accepted by this protocol.

type
  Peer* = ref object of RootObj
    peerId*: int
    protocols*: Table[string, Protocol]

type
  Message* = ref object of RootObj
    ## A `Message` is a piece of data that is sent over the network. Its meaning is typically
    ## protocol-specific.
    messageType*: string
    sender*: Option[Peer]
    receiver*: Peer

type
  Network* = ref object of RootObj
    ## A `Network` is a collection of `Peer`s that can communicate with each other.
    ##
    engine*: EventDrivenEngine
    defaultLinkDelay*: uint64
    peers*: HashSet[Peer] # TODO: use an array
