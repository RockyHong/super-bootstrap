# Test Queue

## Pending

### Snapshot suite re-run after flake fix

- **run on:** main @ the flake-fix merge
- **checklist:**
  - [ ] snapshot suite runs twice → identical output both runs
- **result:** pending
- **source:** DEBT-106
- **on fail:** `/super-bootstrap:log` a bug + re-queue

### New-user tour on tablet

- **run on:** tablet build
- **checklist:**
  - [ ] tour walks end to end → no dead step
- **result:** pending
- **on fail:** `/super-bootstrap:log` a bug + re-queue
