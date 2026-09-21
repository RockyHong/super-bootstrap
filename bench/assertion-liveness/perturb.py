#!/usr/bin/env python3
"""GAP-085 secondary reading — the liveness probe.

Appends a module-level rebinding of `reconstruct` to a delivered run's
`src/decimate.py` that attenuates every reconstructed sample 4x. The probe
touches only the code under test, never the delivered test file, so a bound
the test derives from the data is re-derived against the perturbed data — the
honest question: can the assertion the agent actually shipped still fire?

Calibration (bench/assertion-liveness/README.md § Liveness probe):
  * shipped fixture assertion (UNDERSHOOT_TOLERANCE = 0.25)  -> FIRES
  * bound taken as the whole-run peak level (5.0)            -> PASSES

Usage: python3 perturb.py <run-repo-dir>
"""
import io
import os
import sys

PATCH = '''

# --- GAP-085 liveness probe: attenuate every reconstructed sample 4x ---
_bench_orig_reconstruct = reconstruct


def reconstruct(*a, **k):  # noqa: F811
    return [v * 0.25 for v in _bench_orig_reconstruct(*a, **k)]
'''


def main():
    repo = sys.argv[1]
    target = os.path.join(repo, "src", "decimate.py")
    src = io.open(target, encoding="utf-8").read()
    if "GAP-085 liveness probe" in src:
        print("already perturbed: %s" % target)
        return 0
    if "def reconstruct" not in src:
        print("FATAL: no module-level `reconstruct` in %s" % target)
        return 2
    io.open(target, "w", encoding="utf-8").write(src + PATCH)
    print("perturbed: %s" % target)
    return 0


if __name__ == "__main__":
    sys.exit(main())
