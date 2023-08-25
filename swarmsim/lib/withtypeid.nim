
## This package adds a very basic interface and a macro to annotate and query
## types about their ids at runtime. Type information is queried over a method
## and uses dynamic dispatch, which means you can always recover the actual
## type of an object, even as it is upcasted to more general types.
##
## This is a stopgap measure to allow us to, for instance, register dispatchers
## based on type information, and do type equality comparisons.
##
## NB. This is very naively implemented right now, and won't ensure by a long
##   shot that type IDs - which are currently just the type's name - are unique.
##   If this proves to be a worthwhile effort, however, it would be possible to
##   extend this to use hashes (e.g. signatureHash) or a global counter, and have
##   a separate "typeName" attribute to query the actual name of the type.
##

import options
import macros

method `typeId`*(self: RootObj): string {.base.} =
  ## Returns the type id of an object. This is currently a string and
  ## conflates with the type's human-readable name, but the only hard
  ## requirement is that this is a hashable object and has well-defined
  ## identity semantics (==).
  ##
  ## If a type is not created with the `withTypeId` macro, then the method will
  ## raise an exception unless manually overriden by subtypes.
  raise (ref Defect)(msg: "Type has not been annotated with `withTypeId`.")

method `typeId`*(self: ref RootObj): string {.base.} =
  raise (ref Defect)(msg: "Type has not been annotated with `withTypeId`.")

func typeName(typeDef: NimNode): Option[NimNode] =
  expectKind typeDef, nnkTypeDef

  return if typeDef[0].kind == nnkIdent:
    typeDef[0].some
  elif typeDef[0].kind == nnkPostfix:
    typeDef[0][1].some
  else:
    none(NimNode)

macro withTypeId*(body: untyped): untyped =
  ## Creates a type with a `typeId` method and a proc bound to the type
  ## itself which return the type's name.
  runnableExamples:
    withTypeId:
      type
        Foo = object of RootObj
        Bar* = object of RootObj

    doAssert Foo.typeId == "Foo"
    doAssert Bar.typeId == "Bar"

    doAssert Foo().typeId == "Foo"
    doAssert Bar().typeId == "Bar"

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
      proc typeId*(self: type `typeIdent`): string = `typeName`

    let instanceProc = quote do:
      method typeId*(self: `typeIdent`): string = `typeIdent`.typeId

    # We replace the proc name with a quoted symbol so it turns into a
    # getter.
    typeProc[0][1] = newTree(nnkAccQuoted, typeProc[0][1])
    instanceProc[0][1] = newTree(nnkAccQuoted, instanceProc[0][1])

    body.add(typeProc)
    body.add(instanceProc)

  return body
