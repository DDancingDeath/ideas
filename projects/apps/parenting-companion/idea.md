# Idea — parenting-companion

> **AI-Driven Parenting and Child Growth Companion App** — one app that
> guides me through my child's developmental stages day-to-day **and**
> keeps a live financial plan for her education goals, so I never
> have to context-switch between paediatrician's advice, growth charts,
> vaccination calendars, and SIP statements.

## One-liner

A comprehensive, AI-powered companion for parents: age-specific guidance
on nutrition / habits / education / health, growth tracking against
standard curves, vaccination and check-up reminders, and a financial
planner that ties long-term educational goals (Indian fees + inflation)
to current savings and investments.

## Problem

Parenting a young child needs the parent to keep two very different
horizons in their head at the same time:

- **The short horizon (today / this week).** What should the child be
  eating at this age? How much screen time is okay? Which milestones
  should be emerging right now? When's the next vaccination?
- **The long horizon (10 – 18 years out).** If I want her to do MBBS
  or BTech from a Tier-1 college, what does that cost in 2040 rupees?
  Are my current SIPs enough? Where's the gap?

Today these live in **different apps and different anxieties**:
paediatrician's WhatsApp, a half-remembered IAP chart, a vaccination
booklet that nobody opens, a Google search for "BabyCenter 18 month
milestones", a separate spreadsheet for fee inflation calculations,
yet another app for SIP tracking. Nothing connects.

What I want is **one place that absorbs the child's age + growth +
milestones + my goals + my savings, and turns it into clear, actionable
guidance** — both for tomorrow morning and for fifteen years from now.

## Goal

Build a cross-platform mobile app that:

- Acts as a comprehensive, AI-powered parenting companion.
- Provides age-specific advice on nutrition, habits, education, and
  health that evolves as the child grows.
- Tracks growth and milestones against standard curves.
- Plans long-term financial requirements tied to education goals.
- Suggests, doesn't prescribe — every recommendation is overridable.

## Target users

- **Primary**: me. Indian parent of a young child.
- **Secondary**: other Indian parents (especially first-time parents
  who lack joint-family knowledge transfer and want one trustworthy
  digital companion).
- **Anti-users**: parents who are deep into a paediatrician + financial
  advisor relationship and want a separate spreadsheet per concern.
  Multi-child / multi-parent shared accounts are deferred for v1.

## Key features

### 1. Age-based personalised guidance
- Track the child's age (computed from birthdate).
- Receive tailored recommendations on diet, daily routines,
  educational activities, and good habits.
- Suggestions evolve through life stages: infancy → toddler →
  preschool → school-age → tween → teen.

### 2. Growth tracking
- Periodic input: height, weight, head circumference, developmental
  milestones.
- Visualise growth curves; compare against WHO / IAP standard
  growth charts.
- Track emerging skills: motor, language, social, cognitive.
- Highlight whether the child is on track, ahead, or needs attention.

### 3. Parental guidance
- Practical tips on balancing learning, play, and rest time.
- Concrete advice on how much time should go where: screen vs.
  outdoor play, study vs. rest.
- Age-appropriate boundaries (sleep duration, nap windows, etc.).

### 4. Vaccination & health reminders
- Track the child's vaccination schedule based on official health
  guidelines (WHO, IAP / Mission Indradhanush, paediatrician overrides).
- Timely reminders for upcoming vaccinations and routine health
  check-ups.
- Optional record of which clinic / paediatrician administered each.

### 5. Financial planning for education
- Set long-term goals (e.g. "MBBS by 2042", "engineering at a
  Tier-1 college", "study abroad").
- Calculate estimated education costs based on **current Indian
  education fees + inflation + stage** (school, undergrad, post-grad).
- Track investments and savings (manually entered for v1).
- Real-time **gap analysis**: at current SIP / savings rate, will I
  hit the goal? By how much am I short / over?
- Scenario sliders ("what if I increase SIP by ₹5 000/mo?",
  "what if inflation is 8 % instead of 6 %?").

### 6. Habit building & reminders
- Encourage good habits for both child and parent — reading time,
  family activities, financial check-ins.
- Reminders for daily routines, study time, and "nudges" about
  savings progress.

### 7. Data input & customisation
- Track core metrics (age, weight, height, activities).
- Customise goals, milestones, and financial targets.
- Optional personal journaling / photo logs to document progress.

### 8. AI parental insights
- Personalised insights — spot potential learning gaps, flag if
  habits are off track, recommend enrichment activities based on
  the child's interests and recent milestones.
- LLM operates **over the child's profile** (RAG-style), not as a
  general chatbot.

### 9. Extensibility (modular by design)
- Core: parenting guidance + growth tracking + reminders + financial
  planner.
- Future modules: AI habit recommendations, automated journaling
  (voice → structured entry), wearable integration (Apple Watch / Fitbit
  for sleep + activity), automated financial scenario planning,
  paediatrician-share / school-progress hooks.

## What success looks like

- **Daily usefulness**: the app opens at least 3 times a week without a
  reminder push, because the parent wants to log or look something up.
- **Reminder reliability**: ≥ 95 % of vaccinations and routine
  check-ups land in the parent's calendar before the due date with no
  manual entry.
- **Growth tracking habit**: parent logs height/weight at least once a
  month for the first 5 years.
- **Financial clarity**: parent can answer "am I on track for [child]'s
  college fund?" in < 10 seconds with a number, not a feeling.
- **Personalisation pays off**: AI insights are useful enough that the
  parent acts on at least 1 in 4 of them.

## Constraints

- **Cross-platform** — iOS + Android from day 1. Flutter or React Native.
- **Indian financial reality** — fee data must be Indian (rupees,
  realistic college fees, IAP vaccination schedule). USA/EU defaults
  are not acceptable.
- **Privacy** — health and financial data demands secure storage.
  Local-first (encrypted on-device) with optional sync to a private
  cloud (Azure / OneDrive) is the leading approach.
- **Offline-capable** — the daily-guidance and reminders surfaces
  must work without connectivity. AI insights and cloud sync can
  degrade gracefully.
- **Modular** — core features ship first; AI / wearable / advanced
  financial scenarios slot in later without rewriting the base.

## Non-goals

- A medical-diagnosis tool. The app is not a doctor and should
  visibly say so on advice screens. Symptom checkers are out of
  scope for v1.
- A full SIP / portfolio management tool. The app tracks goal vs.
  current savings; it does not place trades or compete with
  Zerodha / Groww / Cube Wealth.
- A social network for parents. No feeds, no comments, no sharing.
- Multi-child profiles in v1. (May revisit.)
- Multi-parent shared accounts in v1. (May revisit.)
- General-purpose AI chat. Insights are bounded to the child's
  profile and family goals.

## Technical approach

- **Cross-platform mobile framework**: Flutter or React Native (decision
  open). Both deliver iOS + Android from one codebase.
- **AI services**:
  - OpenAI / Azure OpenAI for natural-language insights and
    recommendation generation.
  - Azure Speech (or platform-native) for optional voice journaling.
  - Azure Functions / a thin backend for the financial calculation
    engine if it grows beyond on-device formulas.
- **Data storage**:
  - On-device encrypted SQLite for the canonical profile, growth log,
    reminders, financial inputs.
  - Optional sync to a private cloud (Azure Blob / OneDrive) for
    backup and multi-device.
- **Notifications**: APNs / FCM for reminders.
- **Growth-chart math**: Z-score computation against WHO / IAP
  standard reference tables (bundled with the app).
- **Vaccination schedule**: bundled IAP schedule; paediatrician
  overrides stored per-child.

## Inspiration / prior art

- **BabyCenter** — broad guidance content, weak personalisation, no
  financial layer.
- **Huckleberry** — sleep / routine tracking, AI insights for sleep
  schedules. Solid in its narrow lane.
- **Glow Baby / Nanit** — feeding / growth logs; US-centric.
- **Mission Indradhanush** (Govt. of India) — official vaccination
  schedule reference.
- **Cube Wealth / ET Money / Groww** — investment tracking, no
  parenting context.
- **Mint / YNAB** — budgeting, no education-goal modelling.

The white space is the **junction** — there's no app that combines
age-aware parenting guidance + growth tracking + Indian-context
financial planning into one experience.

## Success criteria — what the user should never have to do

- Cross-reference WHO charts manually in a search engine.
- Maintain a separate spreadsheet for fee inflation.
- Re-enter the child's age every time they open an article.
- Remember the next vaccination date.
- Wonder whether their current SIPs are enough for the chosen goal.

## Open questions

- [ ] **Platform** — Flutter or React Native?
- [ ] **Growth-chart source** — WHO, IAP, or both with a toggle?
- [ ] **Vaccination schedule source** — IAP default; allow
      paediatrician overrides per child?
- [ ] **Education-cost dataset** — where do current fee figures come
      from? How often do they refresh?
- [ ] **Financial engine** — on-device formulas, LLM-driven scenarios,
      or both?
- [ ] **AI services** — OpenAI vs. Azure OpenAI? On-device LLM for
      privacy-sensitive insights?
- [ ] **Data storage** — local-first with optional cloud sync, or
      cloud-first?
- [ ] **Single-parent vs. shared-family account** — v1 single-parent;
      shared comes later. Confirm.
- [ ] **One child vs. multiple children** — v1 one child; multi-child
      changes the data model.
- [ ] **Wearable integration** — defer to a later phase, but design
      the data model to accommodate it?
- [ ] **Existing tools audit** — Huckleberry, BabyCenter, Glow Baby,
      Cube Wealth. Is one of them already close enough?
- [ ] **Medical disclaimer / regulatory** — what does the app need to
      say (and not say) to stay clear of "medical advice" regulation
      in India?
- [ ] **Composition with `notes-reminders`** — voice journaling
      overlaps; should this app push entries into `notes-reminders`
      topics ("Laddu", "Health"), or maintain its own log?
