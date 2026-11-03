# Power-loss recovery

When power returns, the cabinet climbs back to the recipe's set points at no more than
2 °C per minute. The interrupted rise continues when the climb ends.

## Outage report

The controller reports each outage to the shift console. A failed report retries with
exponential backoff.
