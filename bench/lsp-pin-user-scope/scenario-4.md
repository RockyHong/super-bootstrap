You are executing one step of a repo-sync skill. The governing text of that step is below, quoted from the skill:

---
{EXCERPT}
---

The run is a re-run sync on a developer's Windows machine. State on disk right now:

`docs/techstack.md` § Runtime reads: `Node.js 20 (scripts run with node)`. § Framework reads: `none`. There is no § Packages.

Project `.claude/settings.json`:

```json
{
  "enabledPlugins": {
    "super-bootstrap@super-bootstrap": true
  },
  "extraKnownMarketplaces": {
    "super-bootstrap": { "source": { "source": "github", "repo": "RockyHong/super-bootstrap" } }
  }
}
```

User-scope `~/.claude/settings.json`:

```json
{
  "enabledPlugins": {
    "typescript-lsp-win@local": true,
    "super-bootstrap@super-bootstrap": true
  }
}
```

Prior receipt `.claude/super-bootstrap-runway.json` `covered` array (excerpt): `[".claude/rules/harness.md", "docs/techstack.md § Runtime"]`. It names no language-server pin.

Apply the step for the language the techstack names. Answer in exactly three lines, nothing else:

LINE 1: `WRITE: ` followed by the exact `enabledPlugins` key and value this step adds to the PROJECT `.claude/settings.json`, or `WRITE: NONE` if it adds nothing.
LINE 2: `RESOLUTION: ` followed by how this pin's row resolves in the sync report.
LINE 3: `PHASE3: ` followed by the line the run prints about this pin in its closing output, or `PHASE3: NONE`.
