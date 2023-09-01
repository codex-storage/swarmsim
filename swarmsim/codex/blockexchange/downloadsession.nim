import std/intsets
import std/tables

import options
import sugar

import ./types
import ../../lib/tables

type BlockStore* = IntSet
type BlockPeerMap* = Table[int, IntSet]
type Block* = int

type
  DownloadSession* = object of RootObj
    manifest*: Manifest
    blocks*: BlockStore
    blockPeerMap*: Table[int, IntSet]

export types

proc storeBlock*(self: var DownloadSession, aBlock: Block) =
  self.blocks.incl(aBlock)

proc storeBlocks*(self: var DownloadSession, blocks: seq[Block]) =
  for aBlock in blocks:
    self.storeBlock(aBlock)

proc queryKnownBlocks*(self: DownloadSession, blocks: Option[IntSet]): IntSet =
  blocks.map(query => self.blocks.intersection(query)).get(self.blocks)

proc queryKnownBlocks*(self: DownloadSession, blocks: Option[seq[Block]] =
    none(seq[Block])): IntSet =
  self.queryKnownBlocks(blocks.map(arr => toIntSet(arr)))

proc storeBlockPeerMapping*(self: var DownloadSession, peerId: int,
    blocks: IntSet) =
  for aBlock in blocks:
    self.blockPeerMap.getDefault(aBlock, peers): peers[].incl(peerId)

proc peersForBlock*(self: DownloadSession, aBlock: Block): IntSet =
  self.blockPeerMap.getOrDefault(aBlock, IntSet())
