# Worked example — one Ask answer across boxes

Synthetic data only. Every figure below is recomputed from the inputs shown.
Contracts: [ask.md](ask.md), [box-contract.md](box-contract.md).

## Setup (synthetic)

| Box | Data |
| --- | --- |
| Hub | `reminders.timezone` set; Today = 2026-10-22; `reminders.upcomingDays` = 14 |
| Finance | Liquid assets ₹6,00,000 (one savings account, liquid tier, no withdrawal haircut). Monthly cash inflow: salary ₹1,50,000. Monthly outflows ₹80,000 = living ₹50,000 + home-loan EMI ₹30,000. Stress assumptions: one-time cost ₹60,000 (school fees) in month 3. Emergency-reserve rule: `target_months` = 3. Health insurance: one employer group policy, linked to employment. |
| Family | Household profile: self; spouse and one child, both `financially_dependent: true` |
| Health | `health.cadences` has a retest whose next due date is 2027-02-15 |
| Career | Learning plan for a target role; time to ready 10 weeks |
| Notes | Reminder "Pay school fees", due 2027-01-10 |

## Question

> "What happens if I take a 6-month career break?"

## Trace

| Step | Result |
| --- | --- |
| Route | Intent `job_loss_or_break`; entity duration = 6 months, starting month 1 (November 2026) |
| Plan | Finance stress (salary stops months 1–6), Finance recommendations, Health due items, Family dependents, Career readiness, reminders due during the gap |
| Run | Finance stress `ok`; recommendations `ok`; Career facts `ok`; Family facts `ok`; Health reminders `ok` |

Stress (balances earn nothing; no income in months 1–6; outflows ₹80,000 a month; ₹60,000 extra in month 3):

| Month | Calculation | Liquid balance at month end |
| --- | --- | --- |
| 1 (Nov 2026) | 6,00,000 − 80,000 | ₹5,20,000 |
| 2 (Dec 2026) | 5,20,000 − 80,000 | ₹4,40,000 |
| 3 (Jan 2027) | 4,40,000 − 80,000 − 60,000 | ₹3,00,000 |
| 4 (Feb 2027) | 3,00,000 − 80,000 | ₹2,20,000 |
| 5 (Mar 2027) | 2,20,000 − 80,000 | ₹1,40,000 |
| 6 (Apr 2027) | 1,40,000 − 80,000 | ₹60,000 |

Total drawn = 6 × ₹80,000 + ₹60,000 = ₹5,40,000 = ₹6,00,000 − ₹60,000. Cash
does not run out within the 6 months. Reserve target = 3 × ₹80,000 =
₹2,40,000; the balance is below it from month 4 (₹2,20,000 < ₹2,40,000; month 3
₹3,00,000 is not).

## Answer

| Field | Content |
| --- | --- |
| `status` | `answered` |
| `answer_summary` | "With no salary for 6 months, your liquid balance would fall from ₹6,00,000 to ₹60,000 by month 6 — ₹5,40,000 drawn, including ₹60,000 of school fees in month 3. Cash does not run out during the break." Every amount has a `refs` entry into the stress output. |
| `aspects_considered` | finance `used` (stress, reserve rule, employer-linked health cover); family `used` (2 dependents); health `used` (a retest due 2027-02-15, inside the break); career `used` (ready for the target role in 10 weeks); notes `used` ("Pay school fees" due 2027-01-10, inside the break); reflection, documents, conversations `not_relevant` |
| `suggestions` (priority order) | 1. *Your health cover ends with your job* — `high`, `protection`. 2. *Balance below your 3-month reserve (₹2,40,000) from month 4* — `high`, `liquidity`. 3. *Retest due 2027-02-15 during the break* — `unrated`, `health_followup`. 4. *Target role ready in 10 weeks — start the learning plan* — `unrated`, `growth`. |
| `caveats` | Break length used for this answer only; stress assumes current outflows continue; health cover status comes from the policy record, not the insurer |
| `follow_ups` | "And if I wait a year?" · "What if the break is 9 months?" · "Can I prepay the home loan first?" |
| `disclaimers` | Finance (`finance.disclaimer`), health, career |
| `checks` | `numbers_traceable: true`, `untraced: []` |

## Follow-up in the same thread

"And if I wait a year?" names no new topic, so it keeps `job_loss_or_break`,
inherits the 6-month duration and moves the start 12 months later (month 13).
`context` lists "duration inherited; start moved by 12 months", and a caveat
says so. The school-fees reminder (2027-01-10) and the retest (2027-02-15) are
no longer inside the break and drop out of `aspects_considered` for notes and
health.
