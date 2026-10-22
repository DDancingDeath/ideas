# End-to-end encryption and sync — Life OS

Everything that leaves a device (sync blobs, encrypted backups) is encrypted
on that device with a key that exists only in memory after the owner types the
passphrase or recovery key. Parameters: [configuration.md § Encryption and
sync](configuration.md#encryption-and-sync). Terms: [glossary.md](glossary.md#security-and-sync).

> **If you lose both your passphrase and your recovery key, your data cannot be
> recovered — by anyone.** The app shows this sentence wherever keys are created.

## Key hierarchy

| Key | Derivation | Purpose |
| --- | --- | --- |
| Data key (DK) | random, `crypto.keyBits` | Root of everything below; one per vault |
| Passphrase key | `crypto.kdf`(passphrase NFC UTF-8, random `crypto.saltBytes` salt, `crypto.pbkdf2Iterations`) | Wraps DK with `crypto.cipher` |
| Recovery key | random `crypto.keyBits`; HKDF-SHA256 with salt = vault id | Wraps DK with `crypto.cipher` |
| Encryption key | HKDF-SHA256(DK, info `lifeos-e2e/1/enc`) | Encrypts data documents and backups |
| Id key | HKDF-SHA256(DK, info `lifeos-e2e/1/doc-id`) | Blob id = HMAC-SHA256(id key, path), first `crypto.blobIdBits` bits |
| Check | HKDF-SHA256(DK, info `lifeos-e2e/1/check`) → HMAC, first 128 bits | Public fingerprint of DK, pinned by every device |
| Connector key | HKDF-SHA256(DK, info `lifeos-e2e/1/connectors`) | Seals connector secrets where OS data protection is unavailable |

| Rule |
| --- |
| Every encryption uses a fresh random `crypto.nonceBits` nonce and a `crypto.tagBits` tag. |
| Associated data names the format version, the object kind and its id: wrap (`passphrase`/`recovery` + vault id), document (blob id + write id), backup (vault id + created time). |
| A keyring is created with at least `crypto.pbkdf2Iterations`; readers accept up to `crypto.pbkdf2MaxIterationsAccepted`. The iteration count is recorded per keyring and may only be raised. |
| Passphrase: at least `crypto.passphraseMinChars` characters; a strength meter is shown at setup (an estimate only). |
| Recovery key: `crypto.keyBits` random bits plus `crypto.recoveryKeyChecksumBytes` checksum bytes, written as `crypto.recoveryKeyFormat`; look-alike characters (0/1/8) are read as O/I/B; typing mistakes are caught before any decryption. Shown once with a printable sheet; setup completes only after "I have saved my recovery key". |
| DK lives only in memory while unlocked. Lock, auto-lock after `vault.autoLockMinutes`, or closing the page wipes it. |
| Without the encryption capability installed, every encrypted operation fails with an install hint; nothing ever falls back to plaintext. |
| The format is identical in every implementation language; committed synthetic test vectors are checked by each. |

## Vault operations

| Operation | Behaviour |
| --- | --- |
| Set up | Passphrase twice → recovery key shown once → confirmed. |
| Join a device | Connect to the relay and unlock with the passphrase, or adopt the keyring of a restored backup (asked). |
| Change passphrase | Re-wrap DK under a new passphrase key (new salt). Documents are not re-encrypted; the recovery key keeps working; the newer keyring spreads at the next sync. |
| New recovery key | Replace the recovery wrap; the old one stops working once the new keyring has spread. |
| Lost passphrase | Unlock with the recovery key, then set a new passphrase. |
| Rotate the data key (lost device) | New DK (same vault, next generation); every document re-encrypted under new blob ids; new keyring uploaded conditionally; old blobs deleted; a new recovery key shown. Other devices stop with `keyring_changed` and unlock again. |
| Forget a device | Revoke its home-server session or relay sign-in, then rotate. |

## What a relay may see

| Sees | Never sees |
| --- | --- |
| The relay account (relay sign-in identity or a `sync` session) | Passphrase, recovery key, data key |
| Opaque blob ids (stable per document, meaningless without the key) | Paths, file names, titles |
| Ciphertext sizes (not padded) and how often each blob changes | Names, figures, report contents, notes, messages |
| Write times; random device ids | Which box a blob belongs to |
| The keyring (salt, parameters, wrapped keys) | — |

Threats protected against: a compromised relay or stolen backup (contents),
tampering (detected by the tag, the associated data and the id check — damaged
blobs are skipped and reported, never applied), keyring substitution (pinned
check). Partly: replay of older genuine blobs (never a silent overwrite;
freshness not guaranteed), a lost device (rotate). Not protected: a script
running as the app on the same origin (mitigated by CSP and auto-lock), a
compromised OS or browser, a coerced owner.

## Sync protocol

| Step | Behaviour |
| --- | --- |
| 1. Keyring | Read the relay's keyring (upload ours if absent). A different check → stop with `keyring_changed`, lock, unlock again. Same check but newer keyring → adopt it (or upload ours if ours is newer). |
| 2. Pull | Every blob changed since the cursor. Decrypt and verify; a failing blob is skipped and reported. A revision counts as seen only once applied or deliberately skipped; the cursor advances only after a successful apply. |
| 3. Push | Every document whose version differs from its synced base; deletes as tombstones; each put conditional on the revision last seen. A concurrent writer → pull and push again, up to `sync.maxPushRounds`. A document the relay refuses (e.g. over its size limit) is listed under *Not synced* and stays on the device; the others are still sent. |
| 4. Device record | A small encrypted record (name, last sync) for *Devices in this vault*. |

| Local state vs incoming record | Result |
| --- | --- |
| Record version = our base | Nothing |
| Local = record version | Base := record version |
| No local change since the base, or path new here | Take it (write, or delete for a tombstone); the old local copy is kept as a backup |
| Both changed since the common base | **Conflict:** the later write (ties by device id) stays at the path; the other is saved as `<path>.conflict-<device>-<UTC timestamp>`, a normal document listed under *Resolve conflicts* (compare side by side, keep one — a versioned save). A deleted side produces no copy. |
| The document is being saved at that moment | Record stays pending; fetched again next pull; push skips that path until applied |

**Offline:** saves keep landing locally and are counted as "waiting to send";
the next sync (manual, on reconnect, or every `sync.autoSyncMinutes`) sends
them. A new device's first sync restores every document with identical
versions. Relays: the owner's home server (no cloud account; relay calls need a
`sync` session) or a free-tier cloud store with owner-only access rules — see
the open question in [README.md](README.md#open-questions).
