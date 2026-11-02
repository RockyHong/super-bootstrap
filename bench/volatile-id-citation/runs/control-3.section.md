## Known limitations

A resumable upload over 2 GB restarts from byte zero after a dropped connection, instead of from the last chunk. A fix is in progress; its status is on the open card in [`docs/work/`](../work/) (search the cards for "2 GB").

