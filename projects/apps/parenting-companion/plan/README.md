# Plan — parenting-companion

## Status

**Early-stage idea capture.** No code. No chosen mobile framework, no
chosen storage model, no chosen Indian-fee data source.

## Next steps

1. **Audit nearby commercial apps** — Huckleberry, BabyCenter, Glow
   Baby, Nanit, Mission Indradhanush, Cube Wealth / ET Money. Confirm
   the *guidance + growth + Indian-context financial planning under
   one roof* framing is the actual gap.
2. **Pick the platform.** Flutter vs. React Native. Decision criteria:
   chart library quality (growth curves), notification reliability,
   developer ergonomics.
3. **Pick the data-storage model.** Local-first encrypted SQLite with
   optional cloud sync is the leading candidate; confirm before any
   code lands.
4. **Source the Indian fee dataset.** This is the long-pole research
   item — pricing data for MBBS, engineering, premier-school fees,
   foreign-study costs. Bundled JSON vs. backend-served vs. crowd-
   sourced. Refresh cadence.
5. **Walking skeleton (v0)** — app shell with child profile entry,
   one growth measurement, one chart against WHO standard curve, one
   hard-coded vaccination reminder. *Goal: prove the daily flow is
   pleasant and the charts look right.*
6. **Add the vaccination schedule + reminder pipeline.** IAP default;
   APNs / FCM wiring; T-7 / T-1 / T-0 reminders.
7. **Add the financial planner.** Goal schema, cost dataset,
   savings inputs, gap analysis, scenario sliders. Pure on-device
   first; no AI yet.
8. **Add the age-stage guidance engine.** Curated content keyed by
   age band; no AI yet.
9. **Add the AI personalisation pass.** LLM over the child's profile
   + recent milestones; structured insight output.
10. **Add journaling + voice entry.** Text + photo first; voice in a
    later phase. Consider composing with `notes-reminders`.
11. **Add wearable hooks.** Schema-only first; live integration later.

## Risks

- **Indian fee dataset goes stale.** If the bundled JSON falls behind
  reality, the financial planner becomes misinformation. Need a clear
  refresh story (in-app pull from a versioned dataset endpoint, or
  "last updated YYYY-MM" banner that prompts the user to verify).
- **Medical-advice regulation in India.** The app must clearly state
  it does not provide medical advice and not over-step into diagnosis.
- **Reminder fatigue.** Too many notifications kills trust. Default to
  conservative cadences and let the parent dial up.
- **Growth-chart anxiety.** Standard curves can scare parents about
  totally normal variation. Wording in insights matters a lot;
  paediatrician-style language ("within typical range") not
  social-media language ("falling behind").
- **Privacy of health + financial data.** Encrypted on-device is the
  minimum bar; cloud-sync design needs to be opt-in per data type.
- **AI hallucinations** in parenting / financial advice can be
  actively harmful. Insights must be **bounded** to the child's
  profile (RAG), structured (not free-text), and always overridable.
- **Existing apps already cover this.** Huckleberry is strong in
  sleep; Mission Indradhanush exists for vaccinations; Cube Wealth
  handles investments. The bet is on the integration; audit first.

## Known issues

(none yet — no code)

## Decision log

(empty — no decisions made yet)
