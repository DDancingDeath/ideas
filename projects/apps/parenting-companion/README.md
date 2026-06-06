# parenting-companion

> An AI-powered companion app for parents — guides me through my child's
> developmental stages (nutrition, habits, education, health) day-to-day,
> and ties long-term goals (e.g. "I want her to become a doctor") to a
> live financial plan that tells me whether my current savings actually
> get us there.

- **Status:** idea capture. No code.
- **Audience:** me. Indian parents with school-age and pre-school
  children. Single-user (per family) for v1.
- **Working title:** `parenting-companion`. Product-name candidates:
  *Nurture*, *Bloom*, *GrowUp*.

---

## The idea

Two things tend to slip while parenting a young child: **day-to-day
age-appropriate decisions** (nutrition portions, screen-time caps,
vaccination dates, the next motor-skill milestone to encourage), and
**long-term planning** (am I actually on track for engineering or
medical college fees fifteen years out, given current Indian education
inflation?). Today these live in different apps, different brains, and
different anxieties.

I want one app where:

1. I enter the child's birthdate, height, weight, and a few milestones.
2. The app gives me **age-specific guidance** that evolves as the child
   grows — diet, routines, learning activities, good habits, the next
   developmental milestones to watch for.
3. The app tracks **growth and milestones** over time and shows me
   where we are vs standard growth curves (WHO / IAP / national).
4. The app keeps **vaccination + health-check reminders** on autopilot.
5. The app lets me set **long-term educational goals** ("become a
   doctor", "Tier-1 engineering college") and computes the **real
   financial plan** — current Indian fee data + inflation + my
   savings + gap analysis — and nudges me about the gap.
6. The app **suggests, doesn't prescribe**. No rigid paths.

Deeper detail: [`idea.md`](./idea.md).

---

## How it might work

```
   parent input  (birthdate, height/weight, milestones, goals, savings)
            │
            ▼
   ┌───────────────────────────────────────────────────────────┐
   │  Child profile + growth log + family goals + investments  │
   └───────────────────────────────────────────────────────────┘
            │
   ┌────────┼─────────────┬──────────────────┬──────────────┐
   ▼        ▼             ▼                  ▼              ▼
  Daily   Growth        Vaccination /      AI parental    Financial
  guide   tracker       health reminders   insights       planner
  (age-   (curves vs    (WHO / IAP         (LLM over      (Indian
  aware)  standards)    schedules)         the profile)   fees +
                                                          inflation
                                                          + savings
                                                          gap)
            │
            ▼
   Reminders + daily/weekly digest (push notifications)
```

The same profile feeds every module. A new milestone update doesn't
just update the growth chart — it can shift the AI's enrichment
suggestions and re-rank the financial scenarios.

---

## Reading order

1. [`idea.md`](./idea.md) — full vision: features, success criteria,
   open questions.
2. [`spec/README.md`](./spec/README.md) — placeholder spec; what it
   needs to cover.
3. [`plan/README.md`](./plan/README.md) — status, walking skeleton,
   roadmap.
4. [`prompts/build-from-spec.md`](./prompts/build-from-spec.md) — hand
   to a coding agent only after the platform + data-source decisions
   are made.

---

## Open decisions

- [ ] **App platform** — Flutter or React Native for cross-platform
      iOS + Android? (User's tech-stack note prefers one of these.)
- [ ] **Growth-chart source** — WHO standards, IAP (Indian Academy of
      Paediatrics) charts, or both with a toggle?
- [ ] **Vaccination schedule source** — IAP / Mission Indradhanush
      schedule by default; allow override per paediatrician?
- [ ] **Education-cost dataset** — where do current Indian fee figures
      come from, and how often do they update? (Curated JSON in-app
      vs. a small backend that refreshes from a public source.)
- [ ] **Financial calculation engine** — pure on-device (formulas
      hardcoded), or LLM-driven scenarios (Azure OpenAI), or both?
- [ ] **AI services** — OpenAI / Azure OpenAI for natural-language
      insights; speech for voice journaling?
- [ ] **Data storage / privacy** — local-first (SQLite on device) with
      optional sync to private cloud (Azure / OneDrive), vs.
      cloud-first from day 1? Health + financial data is sensitive.
- [ ] **Single-parent vs. shared-family account** — v1 single-parent;
      shared comes later. Confirm.
- [ ] **One child vs. multiple children per profile** — multi-child
      changes the data model significantly. Pick early.
- [ ] **Wearable integration** — defer to a later phase, but decide
      whether to leave hooks in the schema now.
- [ ] **Existing tools to audit** — `BabyCenter`, `Huckleberry`,
      `Glow Baby`, `Nanit`, `Cube Wealth` (financial). Confirm the
      "guidance + growth + finance under one roof" framing is the
      gap.

---

## Recent changes

- _2026-06-06_ · Idea captured. No code.
