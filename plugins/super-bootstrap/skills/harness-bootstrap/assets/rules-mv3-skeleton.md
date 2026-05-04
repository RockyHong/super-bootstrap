---
globs:
  - "src/background/**/*.ts"
  - "src/background/**/*.js"
  - "src/content/**/*.ts"
  - "src/content/**/*.js"
description: "Chrome Manifest V3 service-worker & content-script safety. Path-scoped — fires on background/content file reads."
---

# Chrome MV3 Architecture Rules

> Path-scoped rule. Loads with full body when a background or content-script file is read.
> Summary mirrored in `CLAUDE.md` § Rules so the orchestrator knows this rule exists during planning.

These are non-negotiable — violating them silently breaks the extension.

## Service Worker Discipline

1. **Don't import `chrome.*` directly.** Go through the project's polyfill wrapper (typically `src/utils/browserAPI.ts` or `webextension-polyfill`) so feature-detect stays consistent across Chrome / Firefox.
2. **Listeners register at top level** of the worker entry (`src/background/index.ts` or equivalent). Never inside conditional async wrappers — events get lost when the worker wakes from cold.
3. **No DOM APIs in the worker.** Service-worker context only. No `window`, no `document`, no `localStorage`. Use `chrome.storage.local` (or the polyfill) for persistence.
4. **No persistent module-scope state in the worker.** It can be killed at any time. Persist anything you need to remember.
5. **No inline `<script>` and no `eval`.** Manifest CSP forbids it. Separate-file middleware/redirect pages are the workaround pattern.

## API Compatibility

6. **`tabGroups` calls must guard on capability** (`if (browser.tabGroups) ...`). Firefox lacks the API.
7. **Other Chrome-only APIs** — guard or feature-detect before use.

## Async Patterns

8. **Top-level promise chains in listeners always have `.catch`.** Unhandled rejections in MV3 service workers are noisy and cost credibility in store reviews.
9. **Listener returning a promise → return the promise** so the polyfill keeps the worker alive. Don't `await` and then return a plain value if the polyfill is bridging Chrome callbacks.

## Storage

10. **Persisted-key constants belong in a single source of truth** (e.g. `STORAGE_KEYS` in `src/types/storage.ts`). String literals scattered across files cause silent typos.

---

> Grown sections (project-specific worker patterns, snapshot/restore quirks, message-contract idioms) fill via doc-sync as features land.
