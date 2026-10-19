# BUG-t4c9 — release-init's generated /release skill stages into the shared index, exposed to a concurrent plain commit

**Logged:** 2026-10-20 · **Source:** out-of-scope finding from BUG-8zwv's Plan step 3 build (commit door moved off the shared index)
**Problem:** `plugins/super-bootstrap/skills/release-init/assets/template.md:116-122` (and `:167`) runs `git add {{version_file_paths}}` into the shared `.git/index`, reads it back, then runs a plain commit. That is the pattern the commit door just dropped. While the readback stops to ask, the staged version files sit in the shared index, and another session's plain `git commit` takes them (the `bench/commit-guard/` concurrent arm reproduces the class). The generated `/release` skill in consumer repos inherits it.
**Area:** `plugins/super-bootstrap/skills/release-init/assets/template.md`; `plugins/super-bootstrap/skills/release-init/SKILL.md:131`, `:143`
**Prior:** Adopt the commit door's file-grain lane: `git commit -o -- <version files>` with a `git diff HEAD --name-only` readback.
