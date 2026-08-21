# service-probe

Probe every service in a manifest and print one status table.

## What it does

`service-probe` reads `portside.services.toml` from the project root, walks each entry
in declaration order, and issues one request per service. The result is a table: the
service name, the URL probed, the round-trip time, and a verdict.

Probes run concurrently with a small fixed pool, so a manifest of twenty services takes
about as long as its slowest entry rather than the sum of all twenty. Declaration order
is still what the table prints in — the concurrency is invisible in the output.

The exit code is 0 when every verdict is `up`, and 2 otherwise. Nothing about the exit
code distinguishes which failure happened; that is what the table is for.

## The fact

A `200` proves that something accepted the connection and answered. It does not prove
the service finished booting, loaded its config, connected to its database, or is ready
to take real traffic.

Frameworks answer their health route long before they are usable, and a probe cannot
tell the difference from outside. Readiness is a claim only the service itself can
make. `service-probe` reports what the socket did, and stops there.

Treating this table as a gate — blocking a test run until every row is `up` — reads a
guarantee into it that is not there.

## Failure modes

- **Timeout.** The probe retries twice with a fixed backoff, then reports
  `unreachable`. Three timeouts in a row is a service that is down or a port that is
  wrong; one is usually a cold start.
- **Redirect chain.** Up to three hops are followed and the final response decides the
  verdict. A chain longer than three hops reports `ambiguous` rather than following
  further, because past that point the probe is measuring a redirect loop.
- **TLS handshake failure.** Reported as `untrusted`, never as `down`. The socket
  answered; the certificate is what the probe rejected, and conflating the two sends
  the reader to restart a service that is running fine.

## Boundary

`service-probe` probes and reports. It never restarts a service, never re-mints a
certificate for the `untrusted` verdict, and never rewrites the manifest — including
the tempting case of a manifest entry whose port has obviously moved.

The command is a reading instrument. Acting on the reading is the developer's, or
another portside command's, job.
