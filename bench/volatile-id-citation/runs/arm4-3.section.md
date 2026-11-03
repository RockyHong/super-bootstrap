## Known limitations

A resumable upload over 2 GB restarts from byte zero after a dropped connection, instead of from the last chunk. The server rejects the resume offset past 2 GB. A fix for the server chunk store is in progress.

