# Power-loss recovery

When power returns, the cabinet starts a recovery ramp: it climbs back to the recipe's
set points at no more than 2 °C per minute, so the crust does not skin over. The panel
shows the ramp's progress, and the interrupted rise continues when the ramp ends.

Hold the door shut with one hand while you check the gasket, then let go.

The controller reports the outage to the shift console over MQTT. A failed report
retries with exponential backoff, and a webhook notifies the bakery manager. The last
set points stay in a local cache until the next successful report.
