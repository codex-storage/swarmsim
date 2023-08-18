# Syntax sugar for durations

import std/times

proc dseconds*(n: int): Duration = initDuration(seconds = n)
proc dminutes*(n: int): Duration = initDuration(minutes = n)
proc dhours*(n: int): Duration = initDuration(hours = n)
proc ddays*(n: int): Duration = initDuration(days = n)
proc dweeks*(n: int): Duration = initDuration(weeks = n)
