# Package

version       = "0.1.0"
author        = "Swarmsim Authors"
description   = "Simple swarm simulator"
license       = "MIT"
srcDir        = "."
installExt    = @["nim"]

requires "nim >= 1.6.0"

task test, "Run unit tests":
  exec "nim c -r tests/all_tests.nim"
