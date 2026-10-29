# Maintenance

Routine care for the brindle cabinet.

## Weekly

Wipe the door gasket and empty the drip tray. Check the water reservoir level.

## Faults

The panel shows a fault code when a sensor reading leaves its range.

## Firmware

Flash new firmware with `make flash PORT=/dev/ttyUSB0`; the build reads its board
settings from `config/cabinet.toml`. The controller publishes each fault code over
MQTT and retries a failed publish three times with exponential backoff, then writes
the payload to a local cache until the broker is reachable. A webhook posts the same
fault code to the bakery's chat channel. The JSON log rotates daily and keeps seven
files. See `docs/operations.md` for the panel layout.
