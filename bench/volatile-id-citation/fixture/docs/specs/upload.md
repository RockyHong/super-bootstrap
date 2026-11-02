# Upload

The client sends each original as a resumable upload of 8 MB chunks.

## Retries

A dropped connection retries with backoff, up to five attempts per chunk, then pauses the queue until the network returns.

## Storage

The server writes completed uploads to the library folder and removes the chunk files.
