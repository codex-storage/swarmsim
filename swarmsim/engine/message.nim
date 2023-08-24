import options
import macros

import ./types

method `messageType`*(self: Message): string {.base.} =
  raise newException(CatchableError, "Method without implementation override")

method `messageType`*(self: FreelyTypedMessage): string = self.messageType

func typeName(typeDef: NimNode): Option[NimNode] =
  expectKind typeDef, nnkTypeDef

  return if typeDef[0].kind == nnkIdent:
    typeDef[0].some
  elif typeDef[0].kind == nnkPostfix:
    typeDef[0][1].some
  else:
    none(NimNode)

macro typedMessage*(body: untyped): untyped =
  expectKind body, nnkStmtList
  expectKind body[0], nnkTypeSection

  for statement in body[0]:
    if statement.kind != nnkTypeDef:
      continue

    let maybeTypename = typeName(statement)
    if maybeTypename.isNone:
      error("unable to get type name from AST. Sorry.")

    let typeIdent = maybeTypename.get
    let typeName = newLit(typeIdent.strVal)

    let typeProc = quote do:
      proc messageType*(self: type `typeIdent`): string = `typeName`

    let instanceProc = quote do:
      method messageType*(self: `typeIdent`): string = `typeIdent`.messageType

    # We replace the proc name with a quoted symbol so it turns into a
    # getter.
    typeProc[0][1] = newTree(nnkAccQuoted, typeProc[0][1])
    instanceProc[0][1] = newTree(nnkAccQuoted, instanceProc[0][1])

    body.add(typeProc)
    body.add(instanceProc)

  return body

export Message, FreelyTypedMessage
