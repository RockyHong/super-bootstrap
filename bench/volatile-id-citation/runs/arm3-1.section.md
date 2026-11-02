## Known limitations

A resumable upload over 2 GB restarts from byte zero after a dropped connection, instead of resuming from the last chunk. The server's chunk index overflows past 2 GB, so it rejects the resume offset. For the status of the fix, check the open cards in the `docs/work/` folder.

