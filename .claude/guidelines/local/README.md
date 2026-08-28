# Project-local lore

Lore this repo owns and cites, held outside the served tree on purpose.

`work-discipline/` is clone-replaced by claude-config-manager's `serve.sh` — the
directory is `rm -rf`'d and re-copied from source whenever it differs
(`scripts/_serve.sh`, the guidelines sync block), so a file this repo owns but the
storehouse does not cannot survive there. A serve never touches this directory.

A file belongs here when this repo cites it and the storehouse has no copy; one
the storehouse carries belongs in `work-discipline/`, served.
