# Privacy and security — Life OS

Encryption, keys and sync: [encryption-sync.md](encryption-sync.md).
Identity facts: [identity-vault.md](identity-vault.md). Constants:
[configuration.md](configuration.md#access-sessions-and-storage).

## Privacy rules

| # | Rule |
| --- | --- |
| P1 | Readable personal data exists only on the owner's devices. Anything that leaves a device is end-to-end encrypted with a key only the owner holds. |
| P2 | Any relay or host stores ciphertext only and is replaceable without data loss. |
| P3 | No analytics, telemetry, third-party scripts, CDNs or external fonts. |
| P4 | The home server is reachable only over loopback and the owner's private network; never from the public internet. |
| P5 | An AI provider sees only what [ask.md § AI provider](ask.md#ai-provider) allows; identity facts never. |
| P6 | Logs, histories, backups and bundles never contain passwords, session tokens, keys or connector secrets. Request logs omit query strings. Logs live outside the data documents. |
| P7 | Health output is factual and non-diagnostic ([boxes/health.md](boxes/health.md#medical-safety)). |
| P8 | The owner can export all data as plain documents and delete it. |
| P9 | The system never asks for a bank, EPFO or other portal password, never scrapes a website and never stores portal credentials. |
| P10 | Source documents are read-only: never moved, renamed, edited or deleted. |
| P11 | Nothing changes the owner's data without the owner's confirmation, except drafts applied under an auto-apply the owner turned on. |
| P12 | Work data (employer mail, chats, Teams, work agents' data) is out of scope ([boxes/conversations.md](boxes/conversations.md#scope)). |

## Home-server access

| Rule |
| --- |
| The server binds `server.bindAddress` only; there is no option to listen on another address. |
| It is published to the owner's devices only through a private-network HTTPS proxy on the same PC (e.g. a tailnet "serve"); a public-internet publication (e.g. a tailnet "funnel") is never used. |
| Requests whose `Host` is not loopback or an exact entry of `auth.allowedHosts` are refused (DNS-rebinding guard). Any allowed host turns sign-in on. |
| Every write (sign-in included) needs an `Origin` (or `Referer`) equal to the request's own host. No CORS, except the sync relay routes for origins the owner allows. |
| Bodies are JSON only and limited by `limits.requestBodyBytes` (statements `limits.statementBodyBytes`; PDFs `health.reportMaxBytes` and `finance.importPdfMaxBytes`). |
| Content-Security-Policy `default-src 'self'`, no inline scripts, `nosniff`. WebAssembly compilation is allowed only where the engines run. |
| The installable app's service worker caches only the app's own static files, never API responses, pages with data or the sign-in page. |
| A liveness route returns no data. |

## Sign-in and sessions

| Rule |
| --- |
| One owner password, stored only as a hash with `auth.passwordKdf` and a random salt. Changing it signs every device out. |
| Every route except sign-in, its static assets, the app-shell files and liveness needs a session: APIs answer `401`, pages redirect to sign-in. |
| Session token: `auth.sessionTokenBytes` random bytes in an `HttpOnly; SameSite=Strict; Path=/` cookie (`Secure` on HTTPS); only its SHA-256 is stored; expiry after `auth.sessionDays`. |
| Session scopes: `app` and `sync`. A `sync` session is accepted only by relay routes, never as the app cookie; it is sent as a bearer token, not a cookie. |
| Settings → Signed-in devices lists sessions (both scopes) and revokes any. |
| Throttling per source: `auth.freeFailures` free failures, then a lockout of `auth.lockoutInitialSeconds` doubling per failure up to `auth.lockoutMaxSeconds` (`429` with `Retry-After`). |
| Every sign-in attempt, sign-out and revocation is appended to a sign-in log (never passwords or tokens). |
| An optional identity header from the private-network proxy may be required in addition to the password; it never replaces it. |

## Connector secrets

| Rule |
| --- |
| OAuth refresh tokens, OAuth client secrets and PDF passwords are sealed at rest with the operating system's per-user data protection, or with the vault's connector key ([encryption-sync.md § Key hierarchy](encryption-sync.md#key-hierarchy)). With neither available nothing is stored. |
| Secrets are never listed as data documents, synced, exported or backed up; the API only returns secret names. |
| Disconnecting a source deletes its secrets and revokes the grant where the provider allows. |

## Calendar feed

The reminders calendar feed is served to a session, or to a private link with
a random key. Only the key's SHA-256 is stored; deleting the link revokes it.
The feed contains reminder titles and dates only.
