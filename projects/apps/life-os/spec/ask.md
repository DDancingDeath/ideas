# Ask — answer contract

Ask takes one free-text question and answers it from every relevant box.
Answers are composed **deterministically from tool outputs**; an AI provider
is optional and may only phrase or propose an intent. Terms:
[glossary.md](glossary.md). Constants: [configuration.md](configuration.md#hub-home-and-ask).

## Pipeline

| Step | Behaviour |
| --- | --- |
| 1. Route | Intents, their phrases, weighted keywords, negative phrases, entity boosts, tool plan, facts per box, cross-box rules, blocking gaps and follow-ups are **data**, inspectable and versioned. Matching runs on the normalised, spell-corrected question; keywords of at least `ask.typoMinWordLength` letters also match one typo away. An intent needs a score ≥ `ask.minScore`. |
| 2. Disambiguate | When two intents score within `ask.tieMargin`, or an "X or Y?" question has a second intent with its own phrase match scoring ≥ `ask.orRatio` of the best, the answer is `needs_input` with a choice of intent — never a silent guess. An intent that `covers` another (a comparison covers a single purchase) does not compete with it. |
| 3. Extract entities | Amounts (₹15 lakh, 15L, 2 crore, 20k, ₹50,000, "two lakhs", "dedh lakh", "12 lakh 50 thousand"), durations and timing ("6 months", "2 saal", "next year", "in 3 years", "by March 2028"), delays ("if I wait a year"), people (relations and names from the household profile), relative ages ("when my son turns 18", "retire at 45"), percentages, health tests (catalogue names and common words such as *sugar*, *cholesterol*), career roles, the item. |
| 4. Execute | Run the intent's tool plan with inputs from stored data documents; entities and inline-form values override inputs **for this answer only** and are never saved. A missing input makes the tool `needs_input`. |
| 5. Compose | Build the answer fields below from tool outputs only. |
| 6. Record | Append the answer to the local history with enough to reproduce it. |

Relative ages resolve against the household profile: exact from a day-precision
birth date; flagged approximate from a partial birth date or an age on a date;
a caveat when the person or age is unknown.

## Answer fields

| Field | Content |
| --- | --- |
| `question` | The text as asked |
| `intent` | The routed intent id, or `fallback` |
| `thread_id` | The conversation thread |
| `status` | `answered`, `needs_input`, `refused` |
| `answer_summary` | Sentences in which every number has a `refs` entry pointing to a tool output path, a fact, a count of engine outputs, the question, or date arithmetic on the profile |
| `aspects_considered` | Per box: `used` / `missing_data` / `not_relevant`, a `reason` (the intent's *why* for that box), facts used, tool calls with `inputs_sha256` and `engine_version`, and the box's missing items that matter (with links) |
| `blocked_by` | Missing items that limit this intent |
| `suggestions` | Box recommendations and cross-box rule results, sorted by the [priority order](box-contract.md#priority-order) |
| `actions` | Deep links that carry this answer's inputs into the matching page as an unsaved draft; follow-ups that lead to a confirmation form |
| `caveats` | Unknown amounts shown as bounds ("at least", "at most"); sample or illustrative data used; stale values with their dates; values used for this answer only; inherited thread context |
| `follow_ups` | Suggested next questions |
| `disclaimers` | One per touched box, the box's disclaimer text |
| `needs` | Inputs to ask for inline when any tool returned `needs_input` |
| `context` | What was inherited from the thread or changed |
| `checks` | `numbers_traceable` (true/false) and `untraced` (numbers with no ref) |

## Cross-box rules

Each intent declares, per box, why the box matters, which facts it contributes
(fact-id patterns) and cross rules `{id, if, suggest {title, why, domains,
urgency, href}}`. Conditions may test facts (status, comparisons, presence or
absence), the reminders feed (due within `reminders.upcomingDays`, before a
purchase month, or during an income gap; title keywords) and a box's own due
items. Examples the rules must cover:

| Question | Boxes that must be considered |
| --- | --- |
| Purchase affordability | Finance affordability and reserve; Family dependents and education goals; payments already due (reminders); Health cover |
| Job loss or career break | Finance stress (runway); employer-linked health cover; dependents; next-role readiness (Career); payments due during the gap |
| A health worry | Results against the lab's ranges; health cover; retests due; dependents |

## Thread context

`POST question + thread_id` continues a thread. A short or follow-up question
("what about 20 lakh?", "and if I wait a year?", "for my son?") that names no
new topic keeps the previous intent and inherits its entities and form inputs
unless it gives its own; "wait a year" moves the previous timing 12 months
later. `context` and a caveat state what was inherited. A thread lasts until
*New conversation*; opening a history item continues its thread.

## Life brief

*Your week* (Home, and questions like "What should I focus on this week?")
contains, each with a link: the top cross-box recommendations by the priority
order; reminders due within `reminders.upcomingDays` (or the days the question
names); an open Reflection review; the missing items that block the most
intents. It never repeats an item shown elsewhere on the same Home screen.

## Refusal scope

| Refused | Answer |
| --- | --- |
| Investment tips (what to buy or sell) | What Ask cannot do, then what it can: allocation facts, goal plans |
| Medical diagnosis or treatment | Cannot diagnose; shows results against the lab's ranges and suggests a doctor |
| Legal advice | Cannot advise; shows the owner's relevant facts |
| Tax filing advice | Cannot advise on filing; shows the [Tax report](boxes/finance.md#tax-report) estimates where one exists |

A refusal never contains a number that is not from the owner's data.

## Safety invariants (checked on every answer)

| # | Invariant |
| --- | --- |
| S1 | Every number in `answer_summary` is traceable (`checks.numbers_traceable`). |
| S2 | Private journal text never appears ([boxes/reflection.md](boxes/reflection.md)). |
| S3 | Nothing is written without the owner's confirmation: "Remind me to…", "save to Notes" and every other write open a pre-filled confirmation form and save only when confirmed. |
| S4 | No diagnosis-like wording. |
| S5 | Identity facts appear masked ([identity-vault.md](identity-vault.md)). |

## AI provider

| Rule |
| --- |
| `ask.provider` = `none`: answers are the deterministic composition only. |
| An external provider (`cloud`) runs only when `ask.allowExternal` is true **and** `ask.share.<boxId>` is true for every box the answer touches. |
| Only the routed intent's facts are sent. Names, employers, labs, document ids and every identity fact are masked before sending; identity facts and message text are never sent unless the source's own consent says so ([boxes/conversations.md](boxes/conversations.md)). |
| Intent proposal by a provider for a question the router could not place additionally needs `ask.share.questionText`; the question is masked first. |
| Any number in provider text that is not in the tool outputs or the question discards the text; the deterministic answer is shown with a caveat. |
| Each answer lists which facts were shared, with which provider. |

## History and feedback

Each answer is appended to a local, append-only history (question, thread,
intent, tool calls, `inputs_sha256`, engine versions, full answer). 👍/👎 with an
optional note and expected intent are stored locally. Neither leaves the
device except inside encrypted sync.

## Evaluation

An evaluation set of realistic questions (English, Hinglish, typos, follow-up
threads, a sparse workspace) states for each the expected intent, the boxes
that must be considered, the entities and answer properties. A release needs
routing accuracy ≥ `ask.eval.routingMinPct` and safety ≥ `ask.eval.safetyMinPct`
(S1–S5).

| Example question | Intent | Expected |
| --- | --- | --- |
| "Can I afford a car for 15 lakh next year?" | `afford_purchase` | amount ₹15,00,000; timing month 12; Finance, Family, Health, Career, Notes considered; finance disclaimer |
| "car le sakta hu 15L mein?" | `afford_purchase` | amount ₹15,00,000; item car |
| "Can I afford a vacation for two lakhs?" (no saved funding choice) | `afford_purchase` | `needs_input` for how it would be paid; nothing written |
| "Is it okay to buy a 25 lakh SUV when my son turns 5?" | `afford_purchase` | purchase month resolved from the son's birth date |
| "What should I focus on this week?" | `life_brief` | life brief |
