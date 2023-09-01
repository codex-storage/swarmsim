import std/intsets
import std/tables
import options

import ../../lib/withtypeid
import ../../engine

import ./downloadsession
import ./types

withTypeId:
  type
    BlockExchangeProtocol* = ref object of Protocol
      sessions: Table[string, DownloadSession]

    WantHave* = ref object of Message
      cid*: string
      haves*: IntSet
      request*: bool

proc newSession*(self: BlockExchangeProtocol, manifest: Manifest): DownloadSession =
  self.sessions.mgetOrPut(manifest.cid, DownloadSession(manifest: manifest))

proc session*(self: BlockExchangeProtocol, manifest: Manifest): var DownloadSession =
  self.sessions[manifest.cid]

proc handleWantHave*(self: var DownloadSession, message: WantHave,
    network: Network): void =
  self.storeBlockPeerMapping(message.sender.get().peerId, message.haves)

  if message.request:
    discard network.send(WantHave(
      sender: message.receiver.some,
      receiver: message.sender.get(),
      cid: message.cid,
      haves: self.blocks,
      request: false
    ))

proc handleWantHave*(self: BlockExchangeProtocol, message: WantHave,
    network: Network): void =
  self.sessions[message.cid].handleWantHave(message, network)

proc neighborAdded*(
  self: BlockExchangeProtocol,
  parent: Peer,
  neighbor: Peer,
  manifest: Manifest,
  network: Network
) =
  discard network.send(WantHave(
    request: true,
    sender: parent.some,
    receiver: neighbor,
    cid: manifest.cid,
    haves: self.newSession(manifest).blocks
  ))

method deliver*(
  self: BlockExchangeProtocol,
  message: Message,
  engine: EventDrivenEngine,
  network: Network
): void  =
  if message of WantHave:
    self.handleWantHave(WantHave(message), network)

proc new*(t: typedesc[BlockExchangeProtocol]): BlockExchangeProtocol =
  BlockExchangeProtocol(messageTypes: @[WantHave.typeId])
