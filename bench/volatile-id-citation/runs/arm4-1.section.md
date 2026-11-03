## Known limitations

A resumable upload over 2 GB restarts from byte zero after a dropped connection, instead of resuming from the last chunk. The server rejects the resume offset past 2 GB.

