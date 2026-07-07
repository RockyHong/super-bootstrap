# Port Rendezvous — Generated Services Bind :0, Publish the Address

A "safe/obscure" literal port picked at generate time (8787, 8000, 3000, 5000,
8080) is LLM-common — trained into weights, so generated tools collide with
*each other*, and a different obscure literal only relocates the collision. The
OS is the only uniqueness authority.

When generated code binds a port AND a separate process must reach it (a hook,
a CLI, a sibling daemon):

1. **Bind an OS-assigned free port** — `bind(host, 0)`; no port literal in the
   generated code, so nothing collides by construction.
2. **Publish `{host, port}` to a fixed-path endpoint file**
   (`~/.<tool>/endpoint.json`) — the rendezvous SSOT: path fixed, contents
   dynamic.
3. **Clients resolve** explicit env override → endpoint file → legacy fallback.
   Absent/dead endpoint = "no service", never an error.

Ownership: the service is the single writer — publish on startup, clear on
graceful shutdown; the launcher clears as surviving parent when a hard kill
skips the service's cleanup. A stale file is non-fatal: a refused connection
self-heals on next launch.

A single process that only talks to itself needs only the free port — the
endpoint file is specifically the rendezvous fix; a fixed port is the lazy
rendezvous, and the lazy rendezvous is what collides.
