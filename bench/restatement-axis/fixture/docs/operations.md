# Operations

Day-to-day handling of a run, from loading trays to pulling them out.

## Loading

Load trays from the bottom shelf up so the lower probe is covered last; a probe
buried between two trays reads the dough, not the air. Leave one finger's width
between a tray and the cabinet wall so the circulation fan can move air past it.

## Starting a run

```sh
brindle start rye-sour
```

`brindle start` takes the schedule's name without the `.toml` suffix, checks the
file parses, and refuses if any stage asks for more than 40 °C.

Expect the first readings after loading to lag the cabinet. The controller samples
each probe every 15 seconds and acts on the mean of the last 8 samples, a 2-minute
rolling window, so the effect of a freshly opened and closed door lingers in the
reading for up to two minutes.

## During a run

Opening the cabinet door pauses the active stage's timer and blocks any stage change
until the door has been shut for 30 seconds, per the
[interlock rule](door-interlock.md#interlock-rule). Check dough through the window
when you can.

`brindle status` prints the live stage, its remaining minutes, and the last averaged
reading. It reads state only and is safe to run as often as you like.

## Unloading

`brindle stop` ends the run early, closes the log, and releases the cabinet. A run
that finished its schedule needs no `stop`: open the door, pull the trays, and the
controller notices the empty cabinet on the next door close.

## Cleaning

Wipe condensation from the probe housings weekly; a film of dried flour on a
humidity probe reads several points dry. Descale the steam generator monthly.
