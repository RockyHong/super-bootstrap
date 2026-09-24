"""Refund bookkeeping: replay protection for refund events.

Upstream payment processors redeliver refund webhooks after timeouts, so the
same refund can reach a batch twice. RefundLedger remembers what has already
been applied and tells the engine to skip a replay.
"""

import logging

log = logging.getLogger(__name__)


class RefundLedger:
    """Remembers applied refunds across batches (backed by `store`, a dict-like)."""

    def __init__(self, store=None):
        self._seen = store if store is not None else {}

    @staticmethod
    def key(ev):
        # Processors do not always echo our refund id back on redelivery, so
        # the replay key is the refund's observable shape.
        return (ev.account_id, ev.amount_cents, ev.posted_on)

    def is_duplicate(self, ev):
        k = self.key(ev)
        if k in self._seen and self._seen[k] != ev.event_id:
            log.info("refund %s skipped as replay of %s", ev.event_id, self._seen[k])
            return True
        return False

    def record(self, ev):
        self._seen[self.key(ev)] = ev.event_id

    def forget(self, ev):
        self._seen.pop(self.key(ev), None)

    def __len__(self):
        return len(self._seen)
