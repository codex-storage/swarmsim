import std/random
import std/math

type Distribution = proc(): float

proc unitUniform(): float =
  ## Uniform distribution on [0, 1]. Used as a building block for inverse
  ## transform samplers
  ## (https://en.wikipedia.org/wiki/Inverse_transform_sampling), as well as
  ## for the scaled uniform distribution.
  rand(1.float)

proc Exp*(lambda: float, unitUniform = unitUniform): Distribution =
  ## Returns an exponential `Distribution` with parameter lambda.
  proc(): float = -ln(1 - unitUniform()) / lambda
