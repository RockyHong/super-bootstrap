# GAP-7xv6 — needs-me may miss a wait named inside a Design block body

**Logged:** 2026-11-24 · **Source:** `DEBT-mmf6` triage verdict (2026-11-24), flagged unverified
**Problem:** `docs/work/README.md` says a Design ruling that names `waiting on {party}` makes needs-me read the card as waiting, but `needs-me/SKILL.md` § scan reads only each card's origin block plus its latest `## ` heading, so a wait written in a Design block's body may never reach the user-wall sort (scope per the `DEBT-mmf6` triage verdict, unconfirmed)
**Area:** `plugins/super-bootstrap/skills/needs-me/SKILL.md`, `docs/work/README.md` § Thread contract, `plugins/super-bootstrap/skills/harness-bootstrap/assets/work-readme-skeleton.md`
**Prior:** Either needs-me reads the latest block's body, or the README stops claiming the Design body is read.
