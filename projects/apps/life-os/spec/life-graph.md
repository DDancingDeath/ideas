# Life graph — Life OS

The life graph is the connected set of everything the system knows about the
owner's life, where every fact cites where it came from. Its storage model is
an open question ([README.md § Open questions](README.md#open-questions)); the
requirements below hold whatever the model.

## Entities

| Entity | Examples | Comes from |
| --- | --- | --- |
| Person | Owner, spouse, child, parent, contact | Household profile; conversation sources (contacts) |
| Account | Bank account, demat, EPF member id, PRAN, folio | Finance inventory, statements |
| Asset | Holding, property, FD | Finance inventory |
| Liability | Loan, card due | Finance inventory |
| Policy | Term life, health insurance | Finance inventory, policy documents |
| Document | A source document (file, email attachment, export) | Documents box, mailbox, imports |
| Identity fact | PAN, Aadhaar, passport number | [Identity vault](identity-vault.md) |
| Event | Birthday, anniversary, school start, maturity, expiry, check-up | Family events, documents, finance items |
| Date | A dated fact (due, maturity, expiry, valuation date) | Any of the above |

## Rules

| # | Rule |
| --- | --- |
| G1 | Every fact has provenance: the calculation that produced it and, when read from a source document, the document id and page (or message id). |
| G2 | Links between entities are recorded, never inferred from names alone. A proposed link (e.g. "this certificate is about this child") is a draft the owner confirms. |
| G3 | A value observed in several sources keeps every observation; the current value is the newest applied observation; conflicting observations are surfaced, not silently merged. |
| G4 | Ownership is not visibility, and relation is not ownership or dependency (Finance ownership rules apply). |
| G5 | Deleting a source document from the index removes its provenance edges; facts that relied only on it are flagged *source removed*, not deleted. |
| G6 | Ask and nudges read the graph only through facts, tools and reminders of the box contract. |
