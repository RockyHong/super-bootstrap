#!/usr/bin/env bash
# make-fixture.sh — scratch repo for session-close's cross-thread finished-card signal.
# Usage: bash bench/session-close-cross-thread/make-fixture.sh <dir>
#
# A garden newsletter repo, dated commits built with plumbing. Open cards:
#   GAP-tg01  target — its latest Progress (06-02) names the next step: post the seed-swap recap in the newsletter and
#             archive the tally sheet. GAP-an02's 06-09 block posts the recap; the unnamed commit
#             "chore: archive the seed-swap tally sheet" (06-10) archives it. Nothing after 06-02 names GAP-tg01.
#   GAP-an02  the weekly-issue anchor, in motion (next step: the June 16 issue).
#   DEBT-dc03, GAP-dc04, GAP-dc05  decoys sharing topic words (seed-swap, recap, newsletter, archive, tally sheet)
#             whose next step nothing finished.
# This session's own commit (06-12) fixes a README typo. No remote. Writes <dir>.snap.
set -eu
dir="${1:?usage: make-fixture.sh <dir>}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
rm -rf "$dir" "$dir.snap"
mkdir -p "$dir/docs/work" "$dir/records"
cd "$dir"
git init -q -b main
git config user.name bench
git config user.email bench@example.invalid
git config core.autocrlf false
at() { # at <date> <subject>: stage the tree and land it on main at that date
  git add -A
  parent=""; git rev-parse -q --verify HEAD >/dev/null && parent="-p HEAD"
  sha="$(GIT_AUTHOR_DATE="$1T10:00:00" GIT_COMMITTER_DATE="$1T10:00:00" git commit-tree "$(git write-tree)" $parent -m "$2")"
  git update-ref refs/heads/main "$sha"
}

cat > README.md <<'EOF'
# Hollow Lane garden

The newsletter and records of the Hollow Lane community garden. Weekly isues: [`docs/newsletter.md`](docs/newsletter.md).
Swap and harvest tallies: `records/`.
Open work: [`docs/work/`](docs/work/README.md).
EOF
cat > docs/newsletter.md <<'EOF'
# Newsletter

One issue a week, sent on Monday. Each issue has a lead story and a short notices list.

## Issues

- 2026-05-26 — compost rota
- 2026-06-02 — the seed-swap is on
EOF
cat > docs/work/README.md <<'EOF'
# Work cards

One open card per file: `{BUG,DEBT,GAP}-{id}.md`, append-only threads.

## Thread contract

**Resolve:** the resolving session deletes the card file; the deleting commit's message carries the why. A behavior or limitation the resolved card leaves true and no doc yet states lands in the doc that owns it, present-tense. Git history is the archive.
EOF
cat > docs/work/GAP-an02.md <<'EOF'
# GAP-an02 — weekly newsletter issues

**Logged:** 2026-05-20 · **Source:** garden committee
**Problem:** The weekly issue has no owner; each week someone has to assemble and send it.
**Area:** `docs/newsletter.md`

## Plan — 2026-05-20

Each week: collect the stories, assemble the issue, send it Monday, list it in `docs/newsletter.md`.
EOF
printf 'placeholder\n' > records/.keep
at 2026-05-20 "docs: garden newsletter repo"

cat > docs/work/GAP-tg01.md <<'EOF'
# GAP-tg01 — June seed-swap recap

**Logged:** 2026-05-28 · **Source:** garden committee
**Problem:** Members who missed the June seed-swap have no record of what was swapped.
**Area:** `docs/newsletter.md`, `records/`

## Plan — 2026-05-28

1. Run the June seed-swap at the shed.
2. Once the tally closes, post the recap in the newsletter and archive the tally sheet in `records/`.
EOF
at 2026-05-28 "docs(work): log GAP-tg01 — June seed-swap recap"

cat >> docs/work/GAP-tg01.md <<'EOF'

## Progress — 2026-06-02

Step 1 done: the swap ran on June 1. Next step: once the seed-swap tally closes, post the recap in the newsletter and archive the tally sheet in `records/`.
EOF
at 2026-06-02 "docs(work): progress on GAP-tg01"

cat > docs/work/DEBT-dc03.md <<'EOF'
# DEBT-dc03 — seed-swap signup form drops email addresses

**Logged:** 2026-06-03 · **Source:** member report
**Problem:** Signups for the seed-swap lose the member's email address, so the swap reminder never reaches them.
**Area:** the signup form

## Progress — 2026-06-04

Reproduced: the form's email field cuts the address at 20 characters. Next step: widen the seed-swap signup form's email field and retest with a long address.
EOF
at 2026-06-04 "docs(work): log DEBT-dc03 — seed-swap signup form drops email addresses"

cat > docs/work/GAP-dc04.md <<'EOF'
# GAP-dc04 — newsletter recap template

**Logged:** 2026-06-05 · **Source:** garden committee
**Problem:** Each event recap in the newsletter is written from scratch, with a different shape each time.
**Area:** `docs/templates/`

## Plan — 2026-06-05

1. List the sections every recap carries.
2. Write the recap template to `docs/templates/recap.md`.

## Progress — 2026-06-06

Step 1 done: what happened, numbers, thanks, next date. Next step: write the newsletter recap template to `docs/templates/recap.md`.
EOF
at 2026-06-06 "docs(work): log GAP-dc04 — newsletter recap template"

cat > docs/work/GAP-dc05.md <<'EOF'
# GAP-dc05 — 2025 tally sheets

**Logged:** 2026-06-07 · **Source:** garden committee
**Problem:** The 2025 seed-swap and harvest tally sheets exist only on paper in the shed.
**Area:** `records/`

## Progress — 2026-06-07

Sheets found in the shed drawer. Next step: archive the 2025 seed-swap tally sheets in `records/` and link them from `README.md`.
EOF
at 2026-06-07 "docs(work): log GAP-dc05 — 2025 tally sheets"

cat >> docs/work/GAP-an02.md <<'EOF'

## Progress — 2026-06-09

June 9 issue sent. The seed-swap tally closed at 41 packets, and the swap recap ran as the issue's lead story. Next step: assemble the June 16 issue.
EOF
printf -- '- 2026-06-09 — seed-swap recap: 41 packets swapped\n' >> docs/newsletter.md
at 2026-06-09 "docs(work): progress on GAP-an02 — June 9 issue sent"

rm -f records/.keep
cat > records/seed-swap-2026-06.md <<'EOF'
# Seed-swap tally — June 2026

41 packets swapped: beans 12, tomatoes 9, squash 8, herbs 7, flowers 5.
EOF
at 2026-06-10 "chore: archive the seed-swap tally sheet"

sed -i -e 's/Weekly isues/Weekly issues/' README.md
at 2026-06-12 "docs: fix a typo in README"

git reset -q --hard
bash "$here/../session-close-judgment/snapshot.sh" "$dir" > "$dir.snap"
git log --format='%ad %s' --date=short
