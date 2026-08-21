# conflict-report

Cross-check the lease file against what is actually listening, and print the
disagreements.

## What it does

`conflict-report` reads `~/.portside/leases.toml`, enumerates the workstation's
listening sockets, and joins them. Every port that appears in either set gets a row;
ports that appear in both and agree are the boring majority.

The join is by port number only. A lease naming a directory that no longer exists still
counts as a lease — deciding it is dead belongs to `port-sweep`, and a report that
pre-judged it would hide the very state the developer is trying to see.

The command is the usual first move when something is "already in use": it names which
label holds the port and whether anything is actually behind it, in one screen.

## Output

One table, one row per port:

    port | leased-to | listening-pid | verdict

Four verdicts:

- `ok` — leased and listening, and the listening process belongs to the lease holder.
- `orphan` — leased, nothing listening. Usually a dev server that exited without
  releasing.
- `squatter` — listening, no lease. Some other program took a port portside expects to
  hand out.
- `ghost` — leased and listening, but the listening PID does not belong to the lease
  holder. The awkward one: two projects both believe they own the port.

The exit code is `1` when any row carries a verdict other than `ok`, and `0` when every
row is `ok`. That makes the command usable as a pre-flight check in a wrapper script
without parsing the table.

## Boundary

`conflict-report` is read-only. It opens the lease file for reading, reads the process
table, and writes nothing anywhere — not the lease file, not the proxy config, not a
cache.

It never frees a port, never terminates a process, and never rewrites a lease, whatever
the verdict says. Acting on an `orphan` or a `ghost` is `port-sweep`'s job; this command
exists so a human can decide whether to run it.
