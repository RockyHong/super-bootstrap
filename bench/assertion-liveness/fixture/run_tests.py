#!/usr/bin/env python3
"""Plain assert-based test runner. No framework.

Collects every `test_*` function from every `tests/test_*.py`, runs each in
isolation, prints one line per test, exits non-zero if any failed.
"""

import importlib.util
import os
import sys
import traceback

ROOT = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, ROOT)


def load(path):
    name = os.path.splitext(os.path.basename(path))[0]
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def main():
    tests_dir = os.path.join(ROOT, "tests")
    failures = 0
    total = 0
    for fname in sorted(os.listdir(tests_dir)):
        if not (fname.startswith("test_") and fname.endswith(".py")):
            continue
        mod = load(os.path.join(tests_dir, fname))
        for attr in sorted(dir(mod)):
            if not attr.startswith("test_"):
                continue
            fn = getattr(mod, attr)
            if not callable(fn):
                continue
            total += 1
            try:
                fn()
            except Exception:
                failures += 1
                print("FAIL %s::%s" % (fname, attr))
                traceback.print_exc(file=sys.stdout)
            else:
                print("PASS %s::%s" % (fname, attr))
    print("\n%d passed, %d failed, %d total" % (total - failures, failures, total))
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
