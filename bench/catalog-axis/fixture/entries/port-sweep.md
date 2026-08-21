# port-sweep

Free workstation listeners that no live lease or running process owns.

## What it does

`port-sweep` enumerates every listening socket on the workstation, joins it against the
lease file and the process table, and terminates the ones nothing accounts for. It is
the garbage collector for a week of interrupted dev servers.

The sweep runs in two passes. The first classifies without touching anything; the
second acts on the classification. A socket that changes state between the passes — a
process that exits, a port that gets re-bound — is skipped rather than re-classified,
so a sweep never acts on a stale reading.

Sweeping is idempotent. A second run immediately after a first finds nothing and exits
0, which makes it safe to wire into a shell startup file.

## How it identifies a stale listener

Three signals, any one of which marks a listener stale:

- **Orphaned socket** — the owning PID is gone from the process table, but the socket
  is still held by a zombie or a leaked file descriptor in a surviving child.
- **Expired lease** — the port sits inside a lease whose `--ttl` has passed. The
  process may well still be running; an expired lease means nobody renewed it.
- **Lingering `TIME_WAIT`** — the socket has sat in `TIME_WAIT` past the kernel's own
  window, which on a workstation means a crashed process rather than a busy server.

A listener owned by a live process inside a live lease is never stale, whatever it is
doing.

## Arguments

- `--older-than <dur>` — only sweep listeners idle at least this long. Default `0s`,
  which matches **every** listener the classification pass returns, including ones a
  live-but-unleased process is actively serving. Set it to `30m` or more for anything
  running unattended.
- `--yes` — skip the confirmation prompt. It is **assumed** when stdin is not a TTY, so
  a bare `port-sweep` inside a script or a CI step sweeps without asking.
- `--label <name>` — restrict the sweep to listeners inside one lease.
- `--dry-run` — run the classification pass and print, act on nothing.

## Output

A table of freed ports with the label that held them, the PID that was terminated, and
which of the three signals fired. Ports the sweep declined to touch are omitted from
the table; `--dry-run` prints both halves.

A `swept.json` receipt lands in the run directory with the same rows in machine-readable
form, so a wrapper script can diff two sweeps without re-parsing the table.
