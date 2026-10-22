# Box spec — Notes & reminders

Detailed idea: [notes-reminders](../../../notes-reminders/spec/README.md) (this
file wins on the hub contract). The cross-box feed: [nudges.md](../nudges.md).

## Data model

| Document | Fields and bounds |
| --- | --- |
| Note | `{id, created, updated, title (1–200), body (≤ 20 000), tags (≤ 30, each 1–40), topic (≤ 60), links (≤ 50) [{box, ref, label}], pinned, archived}` |
| Reminder | `{id, title (1–200), due, time?, repeat, every_days? (1–3660), status, snoozed_until?, last_done?, note_id?}`; `repeat` ∈ `none`, `daily`, `weekly`, `monthly`, `yearly`, `every_n_days`; `status` ∈ `open`, `done`, `snoozed` |
| Topics | `{topic, keywords[]}` — the owner's list |

## Notes

| Rule |
| --- |
| Body is markdown-lite: headings, bold, italic, lists, checklists, quotes, code, links. Rendering never interprets HTML; only `http(s)://` and in-app links survive. |
| Search: tokenised (Unicode NFKC, lower-case), prefix match for 3+ letters; title and tags weigh most. |
| Topics are only *suggested* (from the owner's keywords, matching tags, topics of notes sharing a tag); the owner sets them. |
| An Ask answer can be saved to Notes only after confirmation. |

## Reminder date rules

| Rule |
| --- |
| Occurrence *k* is computed from the anchor (first due) date, never from the previous occurrence: a monthly reminder on the 31st falls on the 30th / 28th (29th) and returns to the 31st; a yearly one on 29 February falls on 28 February in other years. |
| `every_n_days` adds `every_days` × k days to the anchor. |
| Marking a repeating reminder done skips any missed occurrences to the next one after Today. |
| Snooze hides a reminder until a local date-time. |
| "Today" follows [cross-cutting.md § Dates](../cross-cutting.md#dates-and-time-zone). |
| "Remind me to … on …" in Ask (and the quick-add field) produces a draft parsed from the text and saves only after the owner confirms. |
