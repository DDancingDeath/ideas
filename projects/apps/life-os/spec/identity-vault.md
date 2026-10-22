# Identity vault — Life OS

Identity facts are government and account identifiers of the owner and the
household. They are shown masked by default and revealed only after
re-authentication. Constants: `identity.*` in
[configuration.md](configuration.md#documents-and-identity-vault).

## Types and validators

A value that fails its validator is not saved; the owner sees which rule failed.

| Type | Validator | Expiry tracked |
| --- | --- | --- |
| PAN | 10 characters: 5 letters, 4 digits, 1 letter (upper case); the 4th letter is the holder type | no |
| Aadhaar | 12 digits; first digit 2–9; last digit a valid Verhoeff check digit | no |
| Passport (India) | 1 letter + 7 digits | yes (required) |
| Voter ID (EPIC) | 3 letters + 7 digits | no |
| Driving licence | Free text (state formats differ); no format check | yes (required) |
| UAN | 12 digits | no |
| PRAN | 12 digits | no |
| Bank account | 9–18 digits, with its IFSC | no |
| IFSC | 4 letters, `0`, 6 letters or digits | no |
| Other | Free text with an owner label | optional |

Each identity fact records: person, type, value, issue and expiry dates where
relevant, and provenance (the source document and page, or "entered by the
owner").

## Masking and reveal

| Rule |
| --- |
| Everywhere (screens, Ask answers, facts, nudges, exports shown on screen) the value is masked except its last `identity.maskVisibleChars` characters. |
| **Reveal** and **Copy** require re-authentication every time (the sign-in password on the home server, the vault passphrase on the website); the value hides again after `identity.revealHideSeconds`. |
| Every reveal and copy is appended to a local log (time, fact, device). |
| Identity values never appear in logs, notifications, the calendar feed, Ask history in clear, or anything sent to an AI provider. |
| When a vault exists, identity values are stored encrypted with it on the device as well as in sync. |
| Ask "What is my PAN?" answers with the masked value, its source document and a *Reveal* action. |

## From documents

The Documents box may propose identity facts read from a source document
(e.g. a PAN card scan). The proposal is a draft in the identity vault's review
queue; auto-apply never applies identity facts.
