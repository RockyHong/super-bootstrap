# Path Portability

Context-loaded docs — engineering docs, specs, `.claude/**` rules/skills/agents, CLAUDE.md — express filesystem locations in portable forms. A doc that an agent reads into context carries its paths as facts; an absolute machine path is true on exactly one machine, so a clone on another device (or a relocated drive) primes every reader with a stale location.

Fix a broken path by **relativizing, not re-absolutizing**. Sweeping `D:\` → `V:\` buys one move — the new absolute path is just as non-portable across the next device. Portable forms travel with the repo.

## Convention

The generalized template — a consumer's onboarding / env-setup doc instantiates it with concrete values:

| Class | Portable form | Why |
|---|---|---|
| Repo-internal ref | repo-relative, no prefix (`CLAUDE.md`, `docs/…`) | travels with every clone |
| Sibling store / cache | `../<store-dir>` (sibling of repo root) | concrete and portable; stays on the repo's volume |
| Absolute repo root (unavoidable) | a `<repo-root>` token | clone location is the one irreducibly machine-variable value |
| OS / setup one-off (install cmd) | concrete + "(this machine — see <env-setup doc>)" | a literal command run once; lightest touch |

The one concrete machine value — the actual repo-root path on this device — lives only in that env-setup block, nowhere else (SSoT: one truth, one owner).

## Carve-out

One designated setup/playbook doc (the OS-specific install or migration how-to) may carry concrete absolute paths — they're the literal commands a human runs once. Annotate inline ("this machine — see <env-setup doc>"); leave instructional command lines un-relativized.

## Enforcement

The convention is grep-checkable: an absolute-path pattern over the context-loaded doc dirs returns only the intentional env-setup hits, zero in narrative prose. A consumer may wire that check as a path-scoped rule.
