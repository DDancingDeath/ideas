# Build prompt — parenting-companion

> ⚠️ **Do not hand to an agent yet.** Resolve platform (Flutter vs.
> React Native), data-storage model (local-first vs. cloud-first), and
> Indian fee-data source decisions in [`../README.md`](../README.md)
> first. See the project plan in [`../plan/README.md`](../plan/README.md).

---

You are building **parenting-companion**, an AI-powered parenting and
child-growth companion app. Read `../README.md` and `../idea.md` for the
full vision. Generate code in a **separate directory / repo** (not in
this `projects/` folder).

## Walking skeleton (v0)

The first deliverable is a **mobile-first app** that proves the daily
flow is pleasant and the charts look right. No AI, no financial planner,
no insights yet.

1. Child-profile entry: name, birthdate, sex.
2. One growth measurement (date + height + weight).
3. One chart per metric overlaid on the WHO standard curve.
4. One hard-coded vaccination reminder (local notification) to prove the
   reminder pipeline end-to-end.
5. Encrypted on-device SQLite for the profile + measurements.

## Quality bar (v0)

- **Onboarding**: child profile complete in < 60 s.
- **Measurement entry**: under 15 s per logged measurement.
- **Chart render**: < 500 ms with 50 measurements.
- **Cold start to home screen**: < 2 s on a mid-range Android device.
- **Offline-first**: every v0 screen works with airplane mode on.

## After v0

Each layer ships as its own PR / milestone, behind a feature flag:

1. Full vaccination schedule (IAP default) + reminder pipeline (APNs /
   FCM + local fallbacks).
2. Routine check-up cadence (well-baby, dental, vision).
3. Milestone catalogue (motor / language / social / cognitive) with
   checkable, age-banded entries.
4. Age-stage daily guidance engine (curated content; no AI yet).
5. Financial planner: goal schema, bundled Indian fee dataset, savings
   inputs, gap analysis, scenario sliders (pure on-device).
6. AI personalisation pass: LLM over the child's profile + recent
   milestones; structured insight output (kind, evidence, suggested
   action). Bounded RAG, not free chat.
7. Journaling (text + photo).
8. Voice journaling — consider composing with `notes-reminders`.
9. Optional cloud sync (Azure Blob / OneDrive), opt-in per data type
   (profile + measurements separate from financial).
10. Wearable schema hooks (Apple Watch / Fitbit) — design only, no
    live integration yet.

## Do NOT

- Implement a symptom checker or medical-diagnosis flow. The app is
  not a doctor. Every advice surface needs a visible disclaimer.
- Integrate with brokerages (Zerodha / Groww) in v1. Manual savings
  entry only.
- Build a social feed, comments, or sharing.
- Default to USA / EU growth charts or vaccination schedules — Indian
  context first (WHO + IAP).
- Send raw health or financial data to any third-party analytics
  service.
- Use free-text AI output for insights — structured output only, with
  evidence pointing back to the data that produced the insight.
- Add streak / gamification mechanics that shame missed entries.
  Tone is paediatrician, not fitness app.
