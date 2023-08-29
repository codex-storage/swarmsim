import unittest

import swarmsim/lib/withtypeid

import ../helpers/compiler

# This is required by "should not allow defining two types with the same name
# in separate modules". Since nim allows us to do imports only at the top, it
# has to be here.
import ./repeated

withTypeId:
  type
    Foo = object of RootObj
    Bar* = object of RootObj
    Qux* = ref object of RootObj

    FooBar = object of Bar

type NonAnnotated = object of RootObj
type NonAnnotatedRef = ref object of RootObj

suite "withtypeid":
  test "should allow querying a type for its id":
    check(Foo.typeId == "Foo")
    check(Bar.typeId == "Bar")
    check(Qux.typeId == "Qux")

  test "should allow querying an instance for its id":
    check(Bar().typeId == "Bar")
    check(Foo().typeId == "Foo")
    check(Qux().typeId == "Qux")

  test "should correctly return the id of the concrete type when upcasted":
    let instance: Bar = FooBar()
    check(instance.typeId == "FooBar")

  test "should raise an error when trying to query the id of a non-annotated type":
    expect(Defect):
      discard NonAnnotated().typeId
      # Note we don't need NonAnnotated.typeId as that won't even compile.

  test "should raise an error when trying to query the id of a non-annotated ref type":
    expect(Defect):
      discard NonAnnotatedRef().typeId

  test "should not allow defining two types with the same name in separate modules":
    check:
      notCompiles:
        withTypeId(true):
          type
            RepeatedName = object of RootObj

{.warning[UnusedImport]: off.}
