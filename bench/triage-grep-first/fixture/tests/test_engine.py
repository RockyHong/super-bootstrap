import unittest
from datetime import date

from tally.engine import StatementEngine
from tally.events import Batch, Event


def ev(eid, kind, acct="A1", amt=0, ref="", memo=""):
    return Event(eid, kind, acct, amt, "USD", date(2026, 8, 15), ref, memo)


class EngineTest(unittest.TestCase):
    def test_charges_accumulate(self):
        e = StatementEngine()
        out = e.run(Batch("b1", "2026-08", [ev("E1", "charge", amt=1000), ev("E2", "charge", amt=250)]))
        self.assertEqual(len(out), 1)
        self.assertEqual(out[0].closing_cents, 1250)

    def test_refund_mid_batch_posts(self):
        e = StatementEngine()
        out = e.run(Batch("b1", "2026-08", [
            ev("E1", "charge", amt=1000),
            ev("E2", "refund", amt=400, ref="E1"),
            ev("E3", "charge", amt=100),
        ]))
        self.assertEqual(out[0].closing_cents, 700)

    def test_refund_superseded_by_dispute(self):
        e = StatementEngine()
        out = e.run(Batch("b1", "2026-08", [
            ev("E1", "charge", amt=1000),
            ev("E2", "refund", amt=1000, ref="E1"),
            ev("E3", "dispute", ref="E1"),
        ]))
        kinds = [l.kind for l in out[0].lines]
        self.assertNotIn("refund", kinds)
        self.assertEqual(out[0].closing_cents, 0)

    def test_balance_carries(self):
        e = StatementEngine()
        e.run(Batch("b1", "2026-07", [ev("E1", "charge", amt=500)]))
        out = e.run(Batch("b2", "2026-08", [ev("E2", "charge", amt=100)]))
        self.assertEqual(out[0].opening_cents, 500)
        self.assertEqual(out[0].closing_cents, 600)


if __name__ == "__main__":
    unittest.main()
