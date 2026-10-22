# Box spec — Documents

The owner points Life OS at the folders where their documents live. The box
re-scans them on the owner's schedule, recognises what each document is,
routes useful data to the right box's review queue and keeps a private
full-text index so Ask can answer from — and cite — the owner's documents.
Settings: `documents.*` in [configuration.md](../configuration.md#documents-and-identity-vault).

## Sources

| Rule |
| --- |
| A source is a folder the owner adds (local, or a cloud drive's synced folder) with include and exclude patterns. Sources are added and removed only by the owner. |
| Source documents are **read-only**: never moved, renamed, edited or deleted. |
| Scans run on `documents.syncSchedule` and on *Sync now*. Without a schedule, only *Sync now*. |
| Scans are incremental by path, size, modification time and SHA-256. Renames and moves are detected by SHA-256; deletions are tracked; duplicate files are reported. |
| Every file read is appended to an audit log (time, path, SHA-256, what was extracted). |

## Extraction

| Kind | Read |
| --- | --- |
| PDF | Text layer; scanned pages by on-device OCR (every OCR value is a draft needing review) |
| Office files (DOCX, XLSX, PPTX) | Text |
| CSV, TXT, MD | Text |
| Images | On-device OCR |
| Password-protected PDF | With a password the owner saved (encrypted, [privacy-security.md § Connector secrets](../privacy-security.md#connector-secrets)); otherwise listed as locked |

## Classification

| Rule |
| --- |
| Deterministic, owner-editable rules (SAMPLE until saved) assign one type with a confidence; the owner can correct it, and a correction is remembered for that file. |
| Types: bank/card statement, mutual-fund CAS, demat CAS, NPS statement, EPF passbook, payslip, Form 16, AIS, ITR, insurance policy, lab report, prescription, résumé, certificate (incl. birth certificate), school document, identity document, receipt/invoice, other. |

## Routing

| Type | Goes to |
| --- | --- |
| Statements, CAS, NPS, EPF, payslip, Form 16, AIS, ITR, policy, receipt | Finance review queue ([finance](finance.md#document-imports)) |
| Lab report, prescription | Health (reports to review; prescriptions stored and indexed only) |
| Résumé, certificate (non-birth) | Career review queue |
| Birth certificate, school document | Family review queue ([birth date flow](family.md#birth-date-from-a-birth-certificate)) |
| Identity document | Identity vault review queue ([identity-vault.md](../identity-vault.md)) |

| Rule |
| --- |
| Every routed draft carries provenance: document id, file, page, observed date. |
| Auto-apply only for rules with `documents.autoApply` true, and never for identity facts or profile changes. |
| Expiry and renewal dates read from a document become reminders after the owner confirms them. |
| An expected document (`documents.expected[]`) not seen within its cadence plus grace raises the *expected document missing* reminder. |

## Index and citations

| Rule |
| --- |
| A full-text index of extracted text lives with the owner's data on the device. It is included in sync (always encrypted) only when `documents.syncIndex` is true. |
| A search page finds documents by words, type and date; results show file, page and snippet. |
| Ask can search the index and cite file + page for statements it makes from a document. Content questions answered by an AI provider follow [ask.md § AI provider](../ask.md#ai-provider) and are not possible while `ask.provider` is `none`. |
| Removing a source drops its documents from the index (see [life-graph.md](../life-graph.md) G5). |
