# brindle

`brindle` drives a bakery proofing cabinet: it reads a proof schedule, holds the
cabinet at each stage's temperature and humidity for the stage's duration, and logs
what the probes saw while the dough rose. It runs on the small controller board
bolted to the cabinet's side panel and talks to the heater, the steam generator, and
two air probes.

## Docs

- [Overview](docs/overview.md) — the moving parts and how a run flows through them.
- [Operations](docs/operations.md) — loading, starting, and unloading a run.
- [Sensors](docs/sensors.md) — the two air probes, wiring, and calibration.
- [Door interlock](docs/door-interlock.md) — what the cabinet does when the door opens.
- [Recipes](docs/recipes.md) — worked schedules for common doughs.

## How it works

A proof schedule is an ordered list of stages read from `schedules/<name>.toml`.
Each stage sets a target temperature, a target humidity, and a duration in minutes.
`brindle` runs the stages strictly in file order, and once the last stage ends the
cabinet drops to a 4 °C hold and stays there until someone unloads it.

Between stages the controller ramps rather than steps: the heater and the steam
generator move toward the next stage's targets at the cabinet's natural rate, and
the next stage's timer starts only when both readings are within tolerance.

## Install

Flash the controller image from the release page onto the board's SD card, insert
it, and power-cycle the cabinet. The board comes up with an empty `schedules/`
directory and a default config at `brindle.toml`.

```sh
brindle doctor
```

`brindle doctor` checks that both probes answer, that the heater relay clicks, and
that the steam generator's water reservoir reads above its low mark.

## Writing a schedule

Create one file per schedule under `schedules/`. Write the stages in order — each
one is a temperature, a humidity, and a number of minutes — and `brindle` runs them
top to bottom, then holds the cabinet at 4 °C until the batch is unloaded.

```toml
[[stage]]
temp_c = 26
humidity = 78
minutes = 45

[[stage]]
temp_c = 30
humidity = 82
minutes = 30
```

Name the file after the dough, not the day: `schedules/rye-sour.toml` is found
again next week, `schedules/tuesday.toml` is not.

## Safety

Opening the cabinet door pauses the active stage's timer and blocks any stage
change until the door has been shut for 30 seconds — see the
[interlock rule](docs/door-interlock.md#interlock-rule).

The heater cuts out above 45 °C regardless of what a schedule asks for. That ceiling
is a hardware fuse on the relay board, not a software setting.

## Troubleshooting

**A stage seems to have been skipped.** Stages run strictly in file order, each with
its own temperature, humidity, and minute count, so check the order of the
`[[stage]]` blocks in `schedules/<name>.toml`. Once the last stage ends the cabinet
sits at a 4 °C hold until unloaded — that hold is expected, not a fault.

**The humidity reading jumps when the cabinet is loaded.** Wet dough releases
moisture fast in the first few minutes. The reading settles on its own; do not
retune the steam generator for it.

**`brindle doctor` reports the reservoir low.** Refill it with filtered water. Tap
water scales the steam generator's element within a season.

## FAQ

**Can I run two schedules at once?** No. One cabinet runs one schedule; a second
`brindle start` refuses while a run is active.

**What happens after the last stage?** A schedule is just its ordered stages from
`schedules/<name>.toml` — temperature, humidity, and minutes each — run in order,
and after the final one the cabinet holds at 4 °C until someone unloads it.

**Where do run logs go?** Each run writes `logs/<schedule>-<run-id>.csv`, one row per
probe sample.

## License

MIT.
