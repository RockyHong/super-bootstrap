# portside — entry catalog

`portside` is a small local-development toolkit for claiming, mapping, and reclaiming
TCP ports on a developer workstation. Each tool ships as one entry file.

> Entries live at `entries/<name>.md`; canonical contract = that file. This index
> carries the summary a reader cut-tests before opening an entry — edit behavior in
> the entry, then follow here.

- `port-claim` — reserves a contiguous block of ports for a labelled project and
  records it in the workstation lease file at `~/.portside/leases.toml`; `--label` is
  required, `--range` sets the block size (default 10), `--from` the search floor
  (default 4000), and `--ttl` the lease life (default 72h); refuses any block starting
  below port 1024 or overlapping a live lease held by another label, and the
  reservation stays advisory — the command never binds the ports itself.
- `proxy-map` — points a `*.test` hostname at a port `port-claim` already reserved,
  rewriting the portside proxy config and reloading the local resolver unless
  `--no-reload` is passed; `--host` and `--port` name the pair and `--label` ties the
  mapping to a lease; on a hostname collision the incumbent mapping wins — the
  newcomer is rejected with a `warn` line naming the holder, so the later project
  picks a different hostname; only the `.test` TLD is served and `/etc/hosts` is never
  touched.
- `tunnel-open` — opens an outbound relay so a claimed local port answers at a
  generated public URL; `--port` selects the port, `--subdomain` fixes the hostname,
  and `--ttl` the lifetime (default 2h); the tunnel also dies with the invoking shell,
  and `--list` prints what is currently live with its remaining time.
- `port-sweep` — finds workstation listeners that no live lease or running process
  owns — an orphaned PID, an expired lease, or a socket stuck in `TIME_WAIT` past the
  kernel window — frees them, and prints a table of what it freed alongside a
  `swept.json` receipt written into the run directory.
- `cert-mint` — issues a 30-day local TLS certificate for a `.test` hostname
  `proxy-map` already serves, signed by the portside dev CA; the CA lands in the OS
  trust store on first run behind a single admin prompt, and Firefox takes the extra
  `--firefox` step because it keeps its own store; private keys stay at
  `~/.portside/certs/` mode `0600` and are never copied into a project tree.
- `service-probe` — walks a service manifest, probes every entry, and prints a status
  table; a 200 there means the socket answered, never that the service finished
  booting, so the table is not a readiness gate; a timed-out probe retries twice
  before reporting `unreachable`, a redirect chain past three hops reports
  `ambiguous`, and a failed TLS handshake reports `untrusted` rather than `down`; the
  command reports only — nothing is restarted and the manifest is never rewritten.
- `env-emit` — writes the project's claimed ports into `.env` as `PORTSIDE_*`
  variables inside a delimited block; `--file` retargets the file, `--prefix` changes
  the variable prefix, and `--stdout` prints instead of writing; nothing outside the
  block markers is ever touched, and an unbalanced marker pair aborts the write rather
  than guessing where the block ends.
- `conflict-report` — cross-checks the workstation lease file against what is actually
  listening and prints a `port | leased-to | listening-pid | verdict` table with
  verdicts `ok`, `orphan`, `squatter`, or `ghost`, exiting 1 when any row is not `ok`;
  strictly read-only — it reports and leaves the freeing to `port-sweep`.
