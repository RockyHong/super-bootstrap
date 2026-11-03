## Known limitations

A resumable upload over 2 GB restarts from byte zero after a dropped connection, instead of resuming from the last chunk. The server chunk store tracks the resume offset in a 32-bit counter, so it rejects offsets past 2 GB.

