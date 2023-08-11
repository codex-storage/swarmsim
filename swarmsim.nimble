# Package

version       = "0.1.0"
author        = "gmega"
description   = "Simple swarm simulator"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["swarm_sim"]


# Dependencies

requires "nim >= 2.0.0"


# Tasks
task test, "Run unit tests":
  exec "nim c -r tests/all_tests.nim"