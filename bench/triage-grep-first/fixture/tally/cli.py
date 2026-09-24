"""tally command line: tally run <batch-file> <period>."""

import sys

from .engine import StatementEngine
from .events import parse_batch
from .money import fmt_money


def main(argv=None):
    argv = list(sys.argv[1:] if argv is None else argv)
    if len(argv) != 3 or argv[0] != "run":
        print("usage: tally run <batch-file> <period>", file=sys.stderr)
        return 2
    _, path, period = argv
    with open(path, encoding="utf-8") as fh:
        batch = parse_batch(path, period, fh.readlines())
    engine = StatementEngine()
    statements = engine.run(batch)
    for st in statements:
        print(f"{st.account_id}\t{fmt_money(st.closing_cents, st.currency)}")
    problems = engine.reconcile_all(statements)
    for acct, ps in problems.items():
        for p in ps:
            print(f"RECONCILE {acct}: {p}", file=sys.stderr)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
