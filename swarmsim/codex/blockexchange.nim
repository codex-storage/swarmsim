import std/intsets
import std/tables
import options

import ../lib/withtypeid

import ../engine

type
  BlockStore* = ref object of RootObj
    store: Table[string, IntSet]

  Manifest* = object of RootObj
    cid*: string
    nBlocks*: uint

withTypeId:
  type
    BlockExchangeProtocol* = ref object of Protocol
      store*: BlockStore

    WantHave* = ref object of Message
      cid*: string
      wants*: IntSet

    Have* = ref object of Message
      cid*: string
      haves*: IntSet

proc new*(t: type BlockExchangeProtocol): BlockExchangeProtocol =
  BlockExchangeProtocol(
    store: BlockStore(store: initTable[string, IntSet]()),
    messageTypes: @[WantHave.typeId, Have.typeId]
  )

proc queryBlocks*(self: BlockStore, cid: string, wants: IntSet): IntSet =
  if not self.store.hasKey(cid):
    return initIntSet()

  return self.store[cid].intersection(wants)

proc storeBlocks*(self: BlockStore, cid: string, blocks: seq[int]): void =
  if not self.store.hasKey(cid):
    self.store[cid] = initIntSet()

  self.store[cid] = self.store[cid].union(toIntSet(blocks))

proc newFile*(self: BlockStore, manifest: Manifest) =
  self.store[manifest.cid] = initIntSet()

proc handleWantHave*(self: BlockExchangeProtocol, message: WantHave): Have =
  Have(
    sender: message.receiver.some,
    receiver: message.sender.get(),
    cid: message.cid,
    haves: self.store.queryBlocks(message.cid, message.wants)
  )

method deliver*(
  self: BlockExchangeProtocol,
  message: Message,
  engine: EventDrivenEngine,
  network: Network
) =
  if message of WantHave:
    discard network.send(self.handleWantHave(WantHave(message)))


