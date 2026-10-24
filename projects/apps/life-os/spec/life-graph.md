# Life graph — Life OS

The life graph is the connected set of everything the system knows about the
owner's life, where every fact cites where it came from. Its canonical store
is the [Knowledge Core](architecture.md#knowledge-core), which defines the
shared entity types and review states; the rules below hold for every fact in
it.

## Where entities come from

Types are defined in [architecture.md § Shared entity types](architecture.md#shared-entity-types-canonical-in-the-core).

| Type | Comes from |
| --- | --- |
| Person, household | Household profile (Me); contacts from chats once the owner links them |
| Organisation | Finance inventory, source documents, career history |
| Account, asset, liability, policy | Finance inventory, statements, policy documents |
| Document | Folders / Documents, mailbox, imports |
| Identity fact reference | [Identity vault](identity-vault.md) |
| Event | Household profile, Family events, source documents, Finance items, Health retests |
| Goal | Finance goals, Family goal links |
| Commitment | Chats (drafts), Notes & reminders |
| Note metadata | Notes & reminders |

## Rules

| # | Rule |
| --- | --- |
| G1 | Every fact has provenance: the calculation that produced it and, when read from a source document, the document id and page (or message id). |
| G2 | Links between entities are recorded, never inferred from names alone. A proposed link (e.g. "this certificate is about this child") is a draft the owner confirms. |
| G3 | A value observed in several sources keeps every observation; the current value is the newest applied observation; conflicting observations are surfaced, not silently merged. |
| G4 | Ownership is not visibility, and relation is not ownership or dependency (Finance ownership rules apply). |
| G5 | Deleting a source document from the index removes its provenance edges; facts that relied only on it are flagged *source removed*, not deleted. |
| G6 | Ask and nudges read shared facts through the Knowledge Core API under a [context policy](context-policy.md), and box results only through facts, tools and reminders of the box contract. |
