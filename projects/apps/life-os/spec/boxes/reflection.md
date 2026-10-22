# Box spec — Reflection

A private journal and periodic reviews. Nothing is scored or interpreted.
Detailed idea: [reflective-friend](../../../reflective-friend/spec/README.md)
(this file wins on the hub contract). Settings: `reflection.*` in
[configuration.md](../configuration.md#reflection).

## Data model

| Document | Fields and bounds |
| --- | --- |
| Entry (one per day) | `{date, mood (reflection.scale), energy (reflection.scale), gratitude[], wins[], worries[] (each ≤ 500), text (≤ 20 000), tags[] (each ≤ 40), shareable}` |
| Review | `{period_id, cadence (weekly \| monthly), answers[{prompt, answer}]}` |

## Rules

| Rule |
| --- |
| Mood and energy use the owner's words from `reflection.moodLabels` / `reflection.energyLabels`. |
| Calendar heatmap, mood/energy series and weekly/monthly averages: days without an entry are gaps, never zeros. Themes are tag frequencies. |
| A review shows the owner's prompts (or labelled SAMPLE prompts) next to each box's state now, what was recorded in the period and the snapshot kept with the previous review. |
| **Journal text is private.** Ask and every other box see only counts and averages (entries, streaks, mood/energy averages, review completion). Text is visible to Ask only from entries the owner marks `shareable`, and never leaves the device except inside encrypted sync. |
| Journal text is never sent to an AI provider. |
| A support note is on the Reflection help page; it is never shown as a reaction to an entry. |
