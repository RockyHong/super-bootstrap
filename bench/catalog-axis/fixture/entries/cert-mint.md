# cert-mint

Issue a local TLS certificate for a hostname `proxy-map` already serves.

## What it does

`cert-mint` generates a keypair, signs a leaf certificate for the requested `.test`
hostname with the portside development CA, and drops both into
`~/.portside/certs/<host>/`. The proxy picks the pair up on its next reload and starts
serving that hostname over HTTPS.

The CA is generated once per workstation on first use and never leaves it. There is no
shared organizational CA to fetch, and no key material is transmitted anywhere — a
mint is entirely local and works offline.

Re-minting a hostname that already holds a valid certificate replaces it. The old leaf
is not revoked, because nothing on the workstation checks revocation; it simply falls
out of the proxy config when the new pair lands.

## Trust store

On first run `cert-mint` installs the development CA into the operating system's trust
store. That is the one step needing elevated rights, and it prompts for administrator
credentials exactly once — subsequent mints reuse the installed CA and run unprivileged.

Firefox does not read the OS trust store. A Firefox user runs `cert-mint --firefox`
once, which writes the CA into every Firefox profile it finds under the user's home
directory. Chrome, Safari, and the usual CLI clients need nothing extra.

Removing the CA is `cert-mint --uninstall-ca`, which pulls it from the OS store and
from any Firefox profile it previously touched, and leaves already-minted leaves in
place as now-untrusted files.

## Rules

Leaf certificates are valid for 30 days. The window is short on purpose: a dev cert
that outlives the project it was minted for is a credential nobody remembers holding,
and a 30-day leaf makes re-minting a routine step rather than an incident.

`cert-mint` refuses a hostname `proxy-map` is not already serving. A certificate for a
name nothing resolves is a file that can only ever be misused, and minting on demand
for arbitrary names turns the local CA into a general-purpose forgery tool.

Private keys stay in `~/.portside/certs/` at mode `0600` and are never copied into a
project tree. `--out` retargets the *certificate*; there is no flag that exports the
key, because a key inside a repo is one `git add -A` away from being published.
