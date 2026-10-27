# Overview

`brindle` is three loops sharing one controller board: a schedule loop that decides
what the cabinet should be doing now, a control loop that moves the heater and the
steam generator toward that, and a log loop that records what the probes report.

## Moving parts

- **Schedule loop.** Reads the active schedule once at `brindle start`, tracks which
  stage is live, and owns the stage timer. Editing the schedule file mid-run changes
  nothing until the next start.
- **Control loop.** Compares the probe reading against the live stage's targets and
  drives two outputs: the heater relay and the steam generator's valve. It is a plain
  on/off controller with a dead band, not a PID loop — a proofing cabinet's thermal
  mass makes anything finer pointless.
- **Log loop.** Writes the run's log file and flushes it on every stage change, so a
  power cut loses at most one stage's tail.
- **Probes.** Two air probes, upper and lower shelf; the details live in
  [Sensors](sensors.md).

## How a reading becomes an action

The controller samples each probe every 15 seconds and acts on the mean of the last
8 samples — a 2-minute rolling window — so a spike from an opened door takes up to
two minutes to wash out of the reading it acts on. The upper and lower probes are
averaged together before the window is applied.

When the averaged reading sits inside the dead band, both outputs stay as they are.
Below it, the heater or the valve opens; above it, they close. The dead band is
±0.5 °C for temperature and ±2 % for humidity.

## The door

Opening the cabinet door pauses the active stage's timer and blocks any stage change
until the door has been shut for 30 seconds — the full
[interlock rule](door-interlock.md#interlock-rule) covers the switch and its fault
states.

## What brindle does not do

It does not bake, it does not schedule across cabinets, and it does not reach the
network: schedules arrive on the SD card and logs leave on it.
