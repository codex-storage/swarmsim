import ./types

method `messageType`*(self: Message): string {.base.} = self.typeId

proc allMessages*(self: type Message): string = "*"

export Message
