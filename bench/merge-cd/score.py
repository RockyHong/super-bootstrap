"""GAP-091 L6 — score merge runs for `cd` use. One TSV row per run + per-arm totals.

For each <tag>.tools.tsv in <runs-dir> (tag = <model>-<arm>-r<n>):

  cd        1 if any Bash/PowerShell command starts with, or chains (after
            &&, ||, ;, |, or a folded newline), a directory change:
            cd / Set-Location / sl / Push-Location / pushd / chdir
  cd_calls  how many shell calls matched
  git_C     shell calls using `git -C <dir>` (reading only — a cd substitute,
            not scored as cd)
  shell     total Bash/PowerShell calls
  absorbed  1 if the final report / commands show both branches merged
            (reading only — reads the run's repo if fixture root given)

Usage: python3 score.py <runs-dir> [fixture-root]
"""
import io
import os
import re
import subprocess
import sys

CD_RE = re.compile(r"(?:^|&&|\|\||;|\||\n)\s*(?:cd|Set-Location|sl|Push-Location|pushd|chdir)(?:\s|$)", re.I)
GITC_RE = re.compile(r"\bgit\s+-C\s", re.I)


def absorbed(fxroot, tag):
    if not fxroot:
        return "-"
    repo = os.path.join(fxroot, "runs", tag)
    try:
        out = subprocess.run(["git", "-C", repo, "branch", "--merged", "main"],
                             capture_output=True, text=True).stdout
    except OSError:
        return "-"
    names = {l.strip("* ").strip() for l in out.splitlines()}
    return int({"feature/a", "feature/b"} <= names)


def main(runs_dir, fxroot):
    print("run\tcd\tcd_calls\tgit_C\tshell\tabsorbed")
    tot = {}
    for name in sorted(os.listdir(runs_dir)):
        if not name.endswith(".tools.tsv"):
            continue
        tag = name[: -len(".tools.tsv")]
        rows = [l.split("\t", 2) for l in io.open(os.path.join(runs_dir, name), encoding="utf-8").read().splitlines()[1:]]
        shell = [r[2] for r in rows if len(r) == 3 and r[1] in ("Bash", "PowerShell")]
        hits = [c for c in shell if CD_RE.search(c)]
        gitc = [c for c in shell if GITC_RE.search(c)]
        ab = absorbed(fxroot, tag)
        print(f"{tag}\t{int(bool(hits))}\t{len(hits)}\t{len(gitc)}\t{len(shell)}\t{ab}")
        for c in hits:
            print(f"  CD {tag}: {c[:200]}")
        key = tag.rsplit("-r", 1)[0]
        t = tot.setdefault(key, [0, 0])
        t[0] += int(bool(hits)); t[1] += 1
    print()
    for k, (c, n) in sorted(tot.items()):
        print(f"TOTAL {k}: cd in {c}/{n} runs")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else None)
