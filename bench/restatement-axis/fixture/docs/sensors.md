# Sensors

`brindle` reads two combined temperature-and-humidity air probes, one above the top
shelf and one below the bottom shelf. Probe calibration has its own section further
down.

## Placement

The upper probe hangs from the cabinet ceiling on its cable, clear of the top tray by
at least 5 cm. The lower probe clips to the rear wall just under the bottom shelf.
Neither probe should touch metal: the cabinet walls run warmer than the air while
the heater is on.

## Wiring

Both probes share the board's two-wire sensor bus. The upper probe is address `0x44`,
the lower `0x45`; the address is set by the solder jumper on the probe's back. Two
probes on the same address read as one probe flickering between two values.

## Calibration

Calibrate each probe on install and every six months after. Put both probes in a
sealed jar with a saturated salt slurry for eight hours; the air above the slurry
sits at 75 % humidity. Run `brindle calibrate upper` and `brindle calibrate lower`
with the jar still sealed. Each command stores an offset that every later reading of
that probe has applied.

Temperature needs no field calibration: the probes ship within ±0.2 °C, inside the
control loop's dead band.

## Replacing a probe

Any probe with the same bus address works as a drop-in replacement. Calibrate the
new one before the next run; an uncalibrated probe carries no offset.
