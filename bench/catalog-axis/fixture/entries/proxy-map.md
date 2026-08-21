# proxy-map

Point a `*.test` hostname at a port `port-claim` already reserved, so a project answers
at `app.test` instead of `localhost:4003`.

## What it does

`proxy-map` writes a host-to-port pair into the portside proxy config and reloads the
local resolver so the name starts resolving without a browser restart. The proxy
itself is a long-lived user service; `proxy-map` only edits its config and signals it.

A mapping is tied to a lease through `--label`. When the lease expires or is swept, the
mapping goes with it on the proxy's next reload — a hostname never outlives the port
it points at.

The reload is the slow part (the resolver flush costs about a second on most
workstations), so a script writing several mappings in a row should pass `--no-reload`
on all but the last.

## Collision handling

Two projects eventually want the same hostname. When `proxy-map` is asked for a
hostname an existing mapping already holds, **the later mapping wins**: the incumbent
is evicted from the proxy config, a `warn` line records which label lost the name, and
the evicted project has to re-run `proxy-map` — against a different hostname, or after
the newcomer releases — before its own URL answers again.

Last-write-wins is deliberate. Rejecting the newcomer instead would leave a developer
staring at a URL that quietly serves someone else's project, which reads as a broken
build rather than a name clash. Eviction is loud and lands on the project that is not
currently being worked on.

## Arguments

- `--host <name>` — the hostname to serve. The `.test` suffix is appended when absent.
- `--port <n>` — the local port to serve it from. Must sit inside a live lease.
- `--label <name>` — the lease the mapping belongs to. Defaults to the lease claiming
  the current directory when exactly one matches.
- `--no-reload` — write the config but skip the resolver flush.

## Boundary

Only the `.test` TLD is served. A request for `app.local` or `app.dev` is refused
rather than mapped: both resolve through real DNS on some networks, and a toolkit that
shadows them turns into an outage no one can trace.

`proxy-map` never edits `/etc/hosts`. The resolver integration is a per-user config the
command owns end to end; a system file it would have to share with the OS installer and
three other tools is not something it will write.
