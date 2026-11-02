## Known limitations

A resumable upload over 2 GB restarts from byte zero after a dropped connection, instead of from the last chunk. A fix is in progress; for its current status, see the open cards in [`docs/work/`](../work/README.md).

