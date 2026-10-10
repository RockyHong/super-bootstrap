#!/usr/bin/env python3
"""Split a retired flat `docs/outward.md` into the thread folder `docs/outward/`.

Usage: python3 split-outward.py <project-root> <readme-skeleton-path>

The sync-side migration for the outward container's flat → folder move. Wholly
mechanical — no per-item judgment, nothing to re-word:

- `<root>/docs/outward.md` is the source. The shipped README skeleton is
  written verbatim as `<root>/docs/outward/README.md`. The flat file's
  `**ID high-water mark:**` line is not carried over: outward IDs come from the
  log skill's generator, so no counter survives the split.
- Each `### OUT-### — {summary}` chunk under `## Entries` becomes
  `<root>/docs/outward/OUT-###.md`: the H1 `# OUT-### — {summary}`, a blank line,
  then the chunk body verbatim (its field lines and anything appended after them),
  trailing blank lines trimmed. Nothing is re-ordered and no field is rewritten,
  so an entry a consumer had already grown blocks on survives intact — except
  that every relative markdown link target gains one `../`: the entry now lives
  one directory deeper than the flat file, so `business/x.md` becomes
  `../business/x.md` and `../assets/y` becomes `../../assets/y`. Absolute,
  `http(s)`, `mailto:` and `#anchor` targets are left alone.
- The flat file is deleted last, after every target has landed.

Refuses (exit 2) rather than overwriting: a target that already exists means the
folder is live and the split has run, so it stops before touching anything.
Prints one line per file written, then the deletion.

Exit codes: 0 split written · 2 usage / source absent / target exists.
"""
import os
import re
import sys

sys.stdout.reconfigure(encoding="utf-8", newline="\n")  # type: ignore[attr-defined]
sys.stderr.reconfigure(encoding="utf-8", newline="\n")  # type: ignore[attr-defined]

CHUNK_HEAD_RE = re.compile(r"^(OUT-\d+) — (.+?)\s*$")
LINK_TARGET_RE = re.compile(r"\]\(([^)\s]+)\)")          # `](target)` — the markdown link target
LINK_KEEP_PREFIXES = ("http://", "https://", "mailto:", "#", "/")


def rebase_links(body):
    """Every relative link target gains one `../` — the entry now sits one
    directory deeper than the flat file it came from."""
    def deeper(m):
        target = m.group(1)
        if target.startswith(LINK_KEEP_PREFIXES):
            return m.group(0)
        return "](../" + target + ")"
    return LINK_TARGET_RE.sub(deeper, body)


def die(msg):
    print(msg, file=sys.stderr)
    sys.exit(2)


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def write(path, text):
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


def entries(flat_text):
    """`### OUT-### — {summary}` chunks under `## Entries`, in file order."""
    out = []
    m = re.search(r"^## Entries\s*$", flat_text, re.M)
    if not m:
        return out
    tail = flat_text[m.end():]
    nxt = re.search(r"^## ", tail, re.M)
    if nxt:
        tail = tail[:nxt.start()]
    for chunk in re.split(r"^### ", tail, flags=re.M)[1:]:
        head, _, body = chunk.partition("\n")
        h = CHUNK_HEAD_RE.match(head)
        if h:
            out.append((h.group(1), h.group(2), rebase_links(body.strip("\n"))))
    return out


def main():
    if len(sys.argv) != 3:
        die("usage: split-outward.py <project-root> <readme-skeleton-path>")
    root, skeleton_path = sys.argv[1], sys.argv[2]
    flat = os.path.join(root, "docs", "outward.md")
    folder = os.path.join(root, "docs", "outward")
    if not os.path.isfile(flat):
        die(f"refuse: {flat} absent — nothing to split")
    if not os.path.isfile(skeleton_path):
        die(f"refuse: skeleton {skeleton_path} absent")

    flat_text = read(flat)
    items = entries(flat_text)

    targets = [(os.path.join(folder, "README.md"), read(skeleton_path))]
    for oid, summary, body in items:
        head = f"# {oid} — {summary}\n"
        targets.append((os.path.join(folder, f"{oid}.md"),
                        f"{head}\n{body}\n" if body else head))

    existing = [p for p, _ in targets if os.path.exists(p)]
    if existing:
        die("refuse: target already exists — the split has already run: "
            + ", ".join(existing))

    os.makedirs(folder, exist_ok=True)
    for path, text in targets:
        write(path, text)
        print(path.replace(os.sep, "/"))
    os.remove(flat)
    print(f"{flat.replace(os.sep, '/')} (deleted — split into docs/outward/)")


if __name__ == "__main__":
    main()
