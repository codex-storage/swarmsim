import std/options

import ./types

export options
export Message

proc new*(T: type Message, sender: Option[Peer] = none(Peer), receiver: Peer, messageType: string): Message =
  Message(sender: sender, receiver: receiver, messageType: messageType)


