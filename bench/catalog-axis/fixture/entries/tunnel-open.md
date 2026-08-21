# tunnel-open

Expose a claimed local port at a generated public URL, for a webhook sender or a phone
on a different network.

## What it does

`tunnel-open` dials out to the portside relay and registers the claimed port behind a
generated hostname. Traffic arriving at that hostname is forwarded down the open
connection to the local port; nothing is bound on the workstation's own interfaces, and
no inbound firewall rule is needed.

The relay terminates TLS with its own wildcard certificate, so the public URL is
`https://` regardless of what the local port speaks. A local service speaking plain
HTTP sees plain HTTP; the `X-Forwarded-Proto` header carries the outside scheme.

Each open tunnel gets its own relay connection. Ten tunnels are ten connections, which
is fine on a workstation and is the reason the relay caps concurrent tunnels per
account rather than per host.

## Lifetime

A tunnel closes when the invoking shell exits — the command holds the connection in the
foreground unless backgrounded, and the relay drops a registration the moment its
connection goes away. It also closes after `--ttl` elapses, default `2h`, whichever
comes first.

`tunnel-open --list` prints every live tunnel for the account with its hostname, target
port, and remaining time. A tunnel started from a shell that has since exited will not
appear, which is the quickest way to tell a dead tunnel from a slow one.

## Arguments

- `--port <n>` — the local port to expose. Must sit inside a live lease.
- `--subdomain <name>` — request a fixed hostname instead of a generated one. Taken if
  free, error if held by another account.
- `--ttl <dur>` — maximum lifetime. Default `2h`, maximum `24h`.
- `--list` — print live tunnels and exit; ignores every other flag.

## Boundary

`tunnel-open` refuses a port that is bound to `0.0.0.0` rather than `127.0.0.1`. A
port listening on every interface is already reachable from the local network, and
relaying it publishes the whole LAN-facing surface through the relay, not the one
service the developer had in mind. Rebind the service to loopback first.

It also refuses to run when `CI` is set in the environment. The relay credential in
`~/.portside/relay.token` is personal and account-scoped: a CI job that opens a tunnel
either leaks that token into build logs or shares one developer's account across every
build on the pipeline. Neither is recoverable by rotating a shared secret, because
there is no shared secret to rotate.
