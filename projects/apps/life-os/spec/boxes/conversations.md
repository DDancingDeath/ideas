# Box spec — Conversations

The owner's **personal** conversations, as a source of people, dates and
commitments. Settings: `conversations.*` in
[configuration.md](../configuration.md#conversations). Open questions are in
[README.md](../README.md#open-questions).

## Scope

| In scope | Out of scope |
| --- | --- |
| WhatsApp personal chats, via the app's official *Export chat* files that the owner imports | Any work data: employer mail, work chats, Teams, work agents' data, anything from a work account or work device. Corporate confidential data stays in sanctioned work tools. |
| SMS and call-log **metadata** (who, when, direction, duration) from the owner's phone app | Recording call audio — never, in any form |
| The owner's own voice notes (the owner's voice only) | Reading chats through unofficial clients, scraping or another person's account |
| **Work bridge** entries: short notes the owner writes in their own words about work commitments that affect personal life (e.g. leave dates, travel) | Importing, pasting or syncing content from work systems into a work bridge entry |

The box offers no connector to any work system. A source the owner marks as
work is refused.

## Sources and retention

| Rule |
| --- |
| A source is one chat export, the phone's message/call metadata, or the voice-notes folder. Each source has `retentionDays` (`required — no default`; "keep forever" is a valid choice) and `aiConsent` (default `false`). A source cannot be imported until its retention is chosen. |
| Messages older than the source's retention are deleted, including from the index; derived facts the owner confirmed (a reminder, a birth date, a last-contact date) are kept. |
| Message text and call metadata are stored only with the owner's data and leave a device only inside encrypted sync. |
| Message text is never sent to an AI provider unless that source's `aiConsent` is true **and** the [Ask provider rules](../ask.md#ai-provider) allow it; identity facts are masked even then. |
| Deleting a source deletes its messages, metadata and index entries. |

## People graph

| Rule |
| --- |
| Each participant becomes a contact in the [life graph](../life-graph.md). A contact is linked to a household-profile person only when the owner confirms the link. |
| Per contact: last contact date (from messages and call metadata), message and call counts by month. |
| A relationship nudge fires when the days since last contact exceed that contact's `conversations.contactIntervalDays` (set per contact; no nudge without it). |

## Commitments

| Rule |
| --- |
| Deterministic, owner-editable phrase rules (English and common Hinglish; SAMPLE until saved) find candidate commitments ("I'll send it tomorrow", "kal call karta hu") by either side, with the date they imply. |
| Each candidate becomes a **draft reminder** citing the message (source, date, sender) in the Conversations review queue. |
| A draft becomes a reminder only when the owner confirms it; auto-apply never applies commitments. Rejected drafts are not proposed again for the same message. |
