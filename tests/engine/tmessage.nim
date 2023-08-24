import unittest

import swarmsim/engine/message

typedMessage:
  type
    PeerAnnouncement* = object of Message
      peerId*: int

    PrivateMessage = object of Message

suite "message":
  test "should automatically generate a type string for typedMessage types":
    check(PeerAnnouncement.messageType == "PeerAnnouncement")
    check(PrivateMessage.messageType == "PrivateMessage")

  test "should automatically generate a type string for typedMessage instances":
    check(PeerAnnouncement(peerId: 1).messageType == "PeerAnnouncement")
    check(PrivateMessage().messageType == "PrivateMessage")

