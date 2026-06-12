# Phase 2 Q&A Rendering Protocol

Self-contained rendering rules for presenting Q&A to the user during Phase 2. Read this before presenting any question.

---

## Render Surface

MCQ-shape (≤4 options) → AskUserQuestion popup, one Q or small batch per call. Free text + synthesis confirm → chat. Tier 1 1-line+y/n stays chat (popup overkill on minimal confirm). Popup tool unavailable → fall back to chat-rendered MCQ, Tier rules unchanged.

---

## Render-Tier Pattern

Pick the cheapest tier that fits. Don't render full per-Q MCQ when a one-line synthesis carries the same information.

### Tier 1 — all required Q's high-confidence + unambiguous

Every signal concrete: README explicit, manifest clear, git activity unambiguous, no missing tool config.

Action: **collapse to a single synthesis line + one y/n**. Don't render Q1-Q4 prose. Skipping the per-Q ceremony is the default for clean, well-described projects.

Example:
```
Detected: {one-line synthesis covering project / user / state / tools}.
Sound right? (y) confirm all  /  (n) show per-Q breakdown
```

### Tier 2 — mixed confidence

Some Q's obvious, some ambiguous.

Action: fold the confident Q's into the synthesis sentence; render full MCQ only for the ambiguous Q's.

### Tier 3 — low confidence on most required Q's

Sparse README, ambiguous package type, contradictory signals.

Action: full per-Q MCQ format, presented serially so user reads each inference.

---

## Tier Escalation

If the user replies `(n)` or pushes back on Tier 1, **promote to Tier 3** for the breakdown — show full per-Q MCQ so they can correct specific items.

---

## MCQ Format Pattern

```
Q{n}. {Question}

Inferred: {default answer}  ({signal — what scan found})

  (a) {default answer}              ← pre-checked
  (b) {alternative 1}
  (c) {alternative 2}
  ...
  (e) other: __
```

User responds with a single key for the obvious case, or types in `e: ...` to elaborate / correct.
