# tally

Nightly statement generation for card accounts. A nightly batch file of events
(charges, refunds, fees, disputes, ...) is parsed into a `Batch` and fed to
`StatementEngine.run()`, which returns one `Statement` per account for the
period. Exports (CSV / PDF layout / JSON), reports (aging, ops summary,
dunning letters), portal API handlers and email notifications render those
statements and account records.

    python3 -m unittest discover -s tests -t .

Work items live in `docs/work/` (one card per file).
