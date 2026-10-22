# Box spec — Career & Learning

Records education, work history, skills, interests, constraints and
aspirations, compares them with **role profiles and learning resources the
owner owns**, and suggests paths and learning plans. No market knowledge
(roles, demand, salaries) is built in. Settings: `career.*` in
[configuration.md](../configuration.md#career--learning). Whose learning this
box covers is an open question ([README](../README.md#open-questions)).

## Calculations

| Calculation | Returns |
| --- | --- |
| Career summary | Experience (overlapping roles merged; complete calendar months), current employer and tenure, timeline with gaps, skills (level on `career.skillScale`, months since last used, evidence count), education, completeness and missing items |
| Skill gap | Per role: gap per skill, weighted fit score (weights from the role profile), missing evidence, learning cover = the fewest total hours that close the gaps (exact up to `career.exactCoverMaxResources` useful resources, otherwise greedy with a warning), cost, uncovered skills, time to ready |
| Path recommendations | Ranked paths by `career.weights` with `career.scoring.*`: score per factor, why, gaps, learning summary, risks, confidence, next steps, cross-box actions; not ranked when data is insufficient |
| Learning plan | For a target role and ordered resources at `career.plan.hoursPerWeek` from `career.plan.startDate`: week-by-week schedule, milestones per skill level, cost per 12-month plan year against `career.plan.yearlyBudget` (a resource's cost counts in the year it starts), progress ahead/behind within `career.plan.onTrackToleranceWeeks`, next session |
| Career facts | Facts for Ask, with hooks to other boxes |

## Rules

| Rule |
| --- |
| No built-in weights or thresholds. Unknown ranking factors are excluded from the score (weights renormalised over known factors) and lower confidence. A profile with no work history or no skills is insufficient data. |
| Skills, interests, aspirations, role profiles and resources carry `source` ∈ {`user`, `sample`, `ai_suggested`}; non-user data adds warnings. |
| Interests match role topics after normalising (case, punctuation, a plural "s") and through the owner's synonym groups (SAMPLE until saved). |
| No finance maths: a path flagged *may require a career break* or *may involve a pay cut* links to Finance affordability / stress. |
| A pasted résumé is split into **draft** roles by date patterns; nothing is saved until confirmed. |
| Recommendations have urgency `unrated` and category `growth`. |
| Disclaimer: *"Suggestions from your own data and chosen role profiles — not career counselling."* |
