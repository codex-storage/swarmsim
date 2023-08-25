import swarmsim/engine/message

type
  FreelyTypedMessage* = ref object of Message
    ## A `FreelyTypedMessage` is a `Message` that can be of any type.
    ##
    messageType*: string

method `messageType`*(self: FreelyTypedMessage): string = self.messageType
