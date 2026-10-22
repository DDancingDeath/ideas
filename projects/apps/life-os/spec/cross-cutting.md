# Cross-cutting rules — Life OS

Rules every box, the hub and both modes (home server, website) obey.

## Dates and time zone

| Rule |
| --- |
| **Today** is the date at `reminders.timezone` (UTC plus the owner's fixed offset; daylight-saving changes are not modelled). One rule for every box, every engine's `as_of`, Home, reminders and both modes. |
| Until the owner sets `reminders.timezone`, Today is the device's local date and Home shows "this device's date — set your time zone". |
| An operator may pin the evaluation date (e.g. for tests or a print-out); a pinned date is shown as such. |
| Engines never read the clock; `as_of` is an input. |
| Day-of-month rules clamp to the month's end (a monthly item on the 31st falls on 30 or 28/29 and returns to 31; 29 February falls on 28 February in other years). |
| Ages are completed months/years at Today; a partial birth date gives an age range flagged *estimated*. |

## No defaults: missing is never zero

| Rule |
| --- |
| A calculation never substitutes a value for an input the owner has not given. It returns `needs_input` with the exact path. |
| An unknown amount is `null`, never `0`. Totals depending on it are `null`; a clearly labelled known-only figure may be shown as a bound ("at least", "at most"). |
| Every owner setting without an agreed value is listed in [configuration.md](configuration.md) as `required — no default` and reported in the box's `missing` until set. |
| Placeholders in forms are hints, never saved values. New goals, plans and settings start empty. |
| The UI shows a missing value as "—" or "not added", never `0`. |
| Nothing is shown in a positive (green) state unless the engine reports it. |

## Sample and illustrative data

| Rule |
| --- |
| Packaged SAMPLE data (stages, milestone catalogue, role profiles, learning resources, topic synonyms, band names, classification and alert rules, prompts, statement categories) is used only until the owner saves their own, and is labelled *sample* on every screen and in every Ask caveat that uses it. |
| A SAMPLE vaccination schedule or band list is never used unless the owner copies it in; it stays marked *sample* until the owner marks it verified. |
| Documents labelled illustrative are shown with an *Illustrative — edit* marker on every result that uses them. |
| No real personal data is ever packaged with the product. |

## Versioned saves and conflicts

| Rule |
| --- |
| Every read of an editable data document returns its `version`. |
| A save must send the version it read (`If-Match`). Without it: `428 version_required`. If the document changed since: `409 version_conflict` with the current version; the UI asks "This was changed in another tab or device — reload, or overwrite with mine?". Overwrite is an explicit choice. |
| Server-side applies (drafts, imports, confirmed Ask writes, sync) check the version they read. |
| Writes are atomic and schema-validated; an invalid document is rejected with every field error and nothing is written. |
| The previous version is kept as a backup: the newest `storage.serverBackupsPerDocument` per document on the home server; `storage.deviceBackupsKeep` on the website. Deletes keep the deleted version as a backup. |
| Canonical file form: UTF-8 without BOM, 2-space indent, LF line ends, one trailing newline, key order preserved; a no-op save changes no byte. |
| A read-only start refuses every write. |

## Backups, export and deletion

| Rule |
| --- |
| The owner can export every data document as one bundle, and import it on another device; every SHA-256 is checked before and after. A plain bundle is not encrypted and the UI says so. |
| An **encrypted backup** is the bundle sealed with the vault ([encryption-sync.md](encryption-sync.md)); it restores on either mode with the passphrase or the recovery key; a wrong key restores nothing. |
| The home server can make encrypted backups on `backup.schedule` (frequency, time, folder, how many to keep — each asked). The unattended passphrase is protected by the operating system's per-user data protection, never stored in plain text or on a command line. |
| A restore into an empty location must have succeeded once before a release is called ready. |
| The owner can delete any data document and all data. |
| Sign-in files (password hash, sessions, sign-in log) are never in a bundle or backup. |

## Accessibility baseline

| Check | Pass when |
| --- | --- |
| Keyboard | Every control reachable; skip link first; focus always visible; dialogs and drawers trap focus, Escape closes and returns focus; no positive `tabindex`. |
| Names | Every image has alt text; every button, link and tab has an accessible name; every field has a label (a placeholder is not a label). |
| Structure | One `h1` per page; heading levels never skip; no duplicate ids. |
| Contrast | Text ≥ 4.5:1 against its background (≥ 3:1 for large text), dimmed states included. |
| Charts | A text alternative for every chart. |
| Phones | No sideways scroll at 390 px width; navigation reachable, including Settings and theme. |
| Motion | With the OS's reduce-motion setting on, no shimmer, slide or smooth scroll. |
| Themes | Dark and light. |
| Confirmations | The app's own confirm dialog (Cancel focused, Escape cancels), never the browser's. |
