# Door interlock

The cabinet door carries a reed switch. `brindle` reads it on every control-loop tick
and treats an open door as a reason to stop moving the run forward.

## Interlock rule

Opening the cabinet door pauses the active stage's timer and blocks any stage change
until the door has been shut for 30 seconds. The heater and the steam generator keep
running against the live stage's targets while the door is open — the cabinet is
trying to recover, not giving up — but no minute of an open-door period counts toward
the stage.

The 30-second settle exists because a door swung shut often bounces open again on
its latch. Counting from the last close rather than the first stops a bounce from
restarting the timer twice.

## Switch faults

A reed switch that reads open for more than 20 minutes straight is treated as
failed, not as a door left ajar. `brindle` logs a `door-switch-stuck` line, resumes
the stage timer, and keeps running the schedule; the status line shows the fault
until the switch reads closed again.

A switch that flickers — more than ten open/close transitions in a minute — is
treated the same way. Both cases resolve themselves the moment the switch reads
steadily closed.

## Wiring

The reed switch sits on the door's hinge side, upper corner, with its magnet on the
frame. It wires to the board's `DOOR` header; polarity does not matter.
