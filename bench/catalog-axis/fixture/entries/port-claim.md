# port-claim

Reserve a contiguous block of TCP ports for one project, so two checkouts on the same
workstation stop fighting over 3000.

## What it does

`port-claim` picks the first free contiguous block at or above a search floor and
records it in the workstation lease file at `~/.portside/leases.toml`. A lease is one
row: the label, the block, the claiming directory, and an expiry.

Leases are per-workstation, not per-repo. Two checkouts of the same project claim
separately and get different blocks — the label disambiguates them in
`conflict-report` output, it does not merge them.

The claim is written before the command returns, so a second `port-claim` racing in
another shell sees the block as taken. The write is atomic (temp file plus rename), so
a killed process never leaves a half-written lease file behind.

Re-running `port-claim` with a label that already holds a live lease is a no-op: it
prints the existing block and exits 0. That makes it safe to drop into a `postinstall`
hook or a dev-server wrapper without guarding the call.

## Arguments

- `--label <name>` — **required**. Names the lease. A name carrying anything a shell
  glob would eat is rejected rather than escaped.
- `--range <n>` — size of the block to reserve. Default `10`. The block is contiguous;
  a fragmented free list means the search walks further up rather than splitting.
- `--from <port>` — search floor. Default `4000`. The search walks upward from there
  and takes the first run of `--range` free ports.
- `--ttl <dur>` — how long the lease lives before `port-sweep` treats it as expired.
  Default `72h`. Accepts the usual `30m` / `12h` / `7d` spellings.

## Boundary

`port-claim` refuses any block that would start below port `1024` — the privileged
range belongs to the machine, not to a dev toolkit — and refuses a block overlapping a
live lease held by another label, even one whose owning process has already died.
Deciding a dead lease is reclaimable is `port-sweep`'s call, not this command's.

The reservation is advisory. `port-claim` never binds the ports; it records intent so
the other portside tools, and a human reading `conflict-report`, can tell a claimed
port from a squatted one. Nothing outside portside consults the lease file, so a claim
does not stop an unrelated program from binding the same port a second later.
