---
globs:
  - "{component path glob — e.g. src/components/**/*.tsx, src/pages/**/*.tsx}"
description: "{Framework} component & styling conventions for this project"
---

# {Framework} Components

> Path-scoped rule. Loads with full body when a component file is read.
> Summary mirrored in `CLAUDE.md` § Rules so the orchestrator knows this rule exists during planning.

## Component Shape

{filled by sp-bootstrap or doc-sync from detected stack — examples:}

{- Function components only (`React.FC<Props>` or equivalent for the framework). No class components.}
{- Default export for the primary symbol; named exports for helpers.}
{- Props extend the relevant DOM `*HTMLAttributes` plus a project-wide `BaseComponentProps` (`className`, `children`).}
{- Variants are object-lookup tables, not switch statements.}

## Styling

{filled by sp-bootstrap or doc-sync from detected stack — examples:}

{- Use the project's class-merge utility (`cn(...)`, `clsx`, `tw-merge`) for conditional classes — pick the one already installed; do not add a new one.}
{- Use semantic theme tokens (`bg-primary`, `text-text-primary`) — never raw hex. New colors go into the theme/config first.}
{- Centralize repeating variant sets into shared components / theme. Inline only layout structure unique to a single JSX block.}

## Type Centralization

{filled by sp-bootstrap or doc-sync — examples:}

{- Domain types shared across UI ↔ background (or UI ↔ API) live in `src/types/` (or equivalent). Component-only prop shapes stay inline.}
{- Persisted-state types and message-contract types are always centralized.}

## Async / Error Handling in Components

{filled by sp-bootstrap or doc-sync — examples:}

{- Prefer `async/await`. Reserve `.then().catch()` for top-level fire-and-forget call sites where awaiting would block listener registration.}
{- Errors logged with a contextual prefix (`console.error("<area>:", err)`) and swallowed only when the caller can recover.}

## Imports

{filled by sp-bootstrap or doc-sync — examples:}

{- Match the dominant style (relative vs `@` alias) — don't mix without reason.}
{- Re-export through barrels where the project has them.}

---

> Grown sections (component-pattern specifics, project-specific gotchas) fill via doc-sync as features land. Bracketed lines `{...}` are placeholders the bootstrap fills from detected stack; lines that don't apply get dropped during scaffold.
