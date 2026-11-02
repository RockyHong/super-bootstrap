## Known limitations

A resumable upload over 2 GB restarts from byte zero after a dropped connection, instead of from the last chunk. The server's chunk index is a 32-bit byte counter, so it rejects resume offsets past 2 GB.

