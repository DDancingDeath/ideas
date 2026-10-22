# Product Specification: Personal AI CFO

Product Vision & Technical Specification · Version 1.0 · October 2026

The goal is to build a personal financial intelligence app that understands your complete financial life, helps you make better decisions, projects your future financial position, and gives you confidence about what you can afford and how securely you're prepared for the future.

This is not just an expense tracker, investment tracker, or chatbot. Think of it as your personal AI CFO — a system that understands where you stand today, where you're heading, what you want to achieve, and what you should do next.

We'll build the personal version first, but design the foundations so it can eventually support family finances, jointly owned assets, shared businesses, rental properties, and collective wealth planning without needing to rebuild everything.

# 1. Product vision

[Novbank - Mobile Fintech Banking Overview Dashboard by Delibix on Dribbble](https://images.openai.com/static-rsc-4/J3IklEvk8M762rjiG1vUG5RXDMJyx3ql3SDScQ73UXLJq_AF6AlEP93Grk2KAOuzCu63Rj6MMQjR5RXkJvfLFOoTrsgR782uUhmz9oNRSagOGHbPjo8VU4t-3NE4YYP1OqbANwwr_2Ws-bFCi3mdn_zBwWwzDj07Tknw6HZ9V8s?purpose=inline)

[dribbble.com](https://dribbble.com/shots/26747562-Novbank-Mobile-Fintech-Banking-Overview-Dashboard)

## Your financial life. One intelligent system.

The app should continuously answer five fundamental questions:

1\. Where do I stand today?

Know your net worth, cash flow, assets, liabilities, insurance coverage, investments, and financial obligations.

2\. Where am I heading?

Project salary growth, EPF and NPS balances, investments, debt reduction, retirement readiness, and future wealth.

3\. Can I achieve my goals?

Understand whether you can afford a car, family vacation, house, children's education, or early retirement without compromising financial security.

4\. What should I do next?

Get prioritized, actionable recommendations on saving, investing, debt repayment, insurance, taxes, and allocating surplus income.

5\. How financially secure am I?

Understand your safety margin, risks, emergency readiness, family protection, and the trade-offs behind every major decision.

## The core promise

You should be able to ask:

- "Can I afford a car next year if I continue paying my home loan?"
- "Can we take a ₹2 lakh family vacation without affecting our long-term plans?"
- "How much will my EPF, NPS, and investments be worth when I'm 45 or 60?"
- "Am I adequately insured for my family?"
- "How much can I safely invest each month?"
- "What happens if I lose my job for six months?"
- "Am I on track to fund my child's education?"
- "What should I prioritize over the next three years?"

The app should answer using your actual financial records, explicit assumptions, and calculated projections — not generic financial advice or numbers invented by an AI model.

# 2. Product strategy: build in versions

The most important architectural decision is to start small without designing ourselves into a corner.

### V1 — Personal AI CFO

Build first

One person's complete financial picture, goals, projections, recommendations, and read-only data imports.

### V2 — Household financial planning

Two spouses, shared goals, individual assets, joint liabilities, children's education, and household cash flow.

### V3 — Family wealth intelligence

Extended family, siblings, parents, shared businesses, rental properties, inherited assets, ownership shares, and collective investment planning.

### V4 — Proactive financial intelligence

Monitors changes, detects risks, identifies opportunities, alerts you when plans go off track, and suggests what to review.

Key recommendation: Build V1 with a multi-person-capable data model, but do not build the family-sharing interface, permissions management, or collective recommendations until the personal experience works well.

The product should also distinguish between a person, a household, a family, and a business. A family member is not automatically entitled to see another member's finances, and being part of the same family does not mean every asset is jointly owned.

# 3. V1 functional requirements

## 3.1 Financial profile and onboarding

The app starts by creating a structured financial profile.

It should collect:

- Age, residence, country, and applicable tax jurisdiction.
- Employment status, employer, salary structure, expected increments, and bonuses.
- Spouse and dependent information relevant to financial obligations.
- Current monthly expenses and savings.
- Retirement age and desired lifestyle.
- Existing and planned financial goals.
- Risk tolerance, investment experience, and liquidity preferences.

Users must be able to skip unknown information and fill it in later. The app should explain why a field matters rather than force the user to complete a long questionnaire.

### Onboarding experience

1. Establish the financial baseline. Add income, expenses, bank balances, investments, properties, and debts.
2. Import available records. Upload statements and payslips, enter account balances manually, and connect supported read-only sources where available.
3. Verify the numbers. Show the app's calculated net worth and let the user correct missing or outdated information.
4. Add goals. Define target amounts, target dates, and priority levels.
5. Generate the first financial plan. Show current financial health, a baseline projection, risks, and the highest-impact next actions.

The user should get useful results even if only 60–70% of their information is available. The app must identify what is missing and show how that affects confidence in its recommendations.

## 3.2 Unified financial inventory

Every financial item should exist in one centralized inventory.

Examples of the records the app should understand

[Indian rupees coins with some Indian currency notes stock photo](https://images.openai.com/static-rsc-4/KWw4pI5EigFNv6l0k4sz2ZiNRBWZvvkEzvFsHfLdOkKdZk6jJ0MPNTL0VNZM-389uZ8-6gD6t6H3lxeEVAStJP6ZS0tOeejyhJt1PGqxSEZU0Xdnx5mK51sbdCvu9qmiVVx_5wiOtJz93IaJCKYVexKooMsFMM4bBbSUVNOeX5wmJp15xjnNFQXGnbiIVpUZ?purpose=inline)

Cash and bank accounts

Savings accounts, current accounts, fixed deposits, recurring deposits, cash balances.

Retirement and investments

EPF, VPF, PPF, NPS, mutual funds, stocks, ETFs, bonds, and other eligible investments.

[The ultimate guide to property investing](https://images.openai.com/static-rsc-4/zfT2-c7AOf65lCHXAR294N3RNXGzHc1dgdxcMJSSqxUzf_mk6l5jI9PT-sjmIKl9b53MvgX8Y8cRxSQW0tJmAEkGojn5TDVQiUCT82PgoPY9NzbPK5p5-qTjBrQi06WKrjZS2IHL5eg6rWqkWc_JLjcNBhs8N_iigR382JuFakI?purpose=inline)

Real estate and ownership

Primary residence, rental properties, land, inherited property, estimated market value, ownership share, and rental income.

[Home Loan: 5 Reasons Why Your Home Loan Application Could Be Rejected - Outlook Money](https://images.openai.com/static-rsc-4/1ZOPYO483DgrOpEfM36r191PyrErXWugoDicOho25OS7QSzsgtfG5Woq5L3u-u-nn19MPK2JtSNsYqH24PnnysvkoGDxNeMU-arqd6svIDvhB9rWmPD54X10e8oJ6ADtUQIBjCUx6iYG0OEzjq_Rsu9anBMetSDMw_K0UA-ruoc?purpose=inline)

Liabilities

Home loans, personal loans, car loans, family borrowings, credit card dues, and other obligations.

[Bright Community Shield Insurance Agency | Protecting What Matters Most](https://images.openai.com/static-rsc-4/GvysNSF9g1iv-Yb3LmgaFswWlcaEbmDLcEaqMNzuliqrBSVLyCyWj-3Jox6kDeYmQiOoGLUKlIWm0N2Le-5tjv7fDv4f-8F_mA2iCOSoYd8K9XusNgqBeQVdyYVBzIe-WFClfe4UyJ1yQM_Y80M1JUEuJD89GTYe4jvvhyov2Rs?purpose=inline)

Insurance and protection

Term life insurance, health insurance, employer coverage, policy premiums, sum assured, exclusions, and renewal dates.

[How Property Investors Protect Rental Property Profitability Long Term](https://images.openai.com/static-rsc-4/8fh8BMJsGAqHc-uX37oNolvpGWSKTvsUJecPszg_wAPR35OpJ16PHcjRJYGWdXEIk_FwKfQ7E2N00BjIrUNA85DxDUQ1CebKx_CKW6VzLHY_-_5yk_WBeP18biSGDQNOWGn-GtSsmU9Aj5kz3mZtfGNfiL8OLyWgcDj9G_8q9Kc?purpose=inline)

Business and other interests

Business ownership, capital invested, distributions, rental income, and other assets that may be added to family planning later.

Each record should store at least:

- Asset or liability type and name.
- Current balance or estimated value.
- Owner and ownership percentage.
- Valuation or balance date.
- Source of information.
- Liquidity and withdrawal restrictions.
- Tax treatment, where relevant.
- Expected growth, interest, or return assumptions.
- Whether the value is verified, estimated, or manually entered.

The app must distinguish market value, cash available, and net worth. For example, ₹1 crore of property equity does not mean ₹1 crore is available to spend.

## 3.3 Income, expenses, and cash flow

The app should understand not only what you own, but how money moves through your life.

### Income sources

- Monthly salary, variable pay, bonuses, and salary hikes.
- Business income and distributions.
- Rental income.
- Dividends, interest, and investment income.
- Other recurring or one-time income.

### Expenses and obligations

- Household spending and essential living expenses.
- Home loan EMI, other EMIs, and family repayments.
- Insurance premiums.
- School fees and children's future education.
- Travel, vehicles, home improvements, and lifestyle spending.
- Taxes, maintenance, and irregular annual expenses.

The app should calculate:

\\[ \text{Monthly Surplus} = \text{Net Income} - \text{Total Outflows} \\]

It should separately track income, spending, savings, investment contributions, and debt principal repayment so that the same rupee isn't counted twice.

For example, a home loan EMI includes both interest and principal. The principal portion reduces the liability; it is not simply another expense for net-worth calculations.

### Cash-flow intelligence

The app should tell you:

- How much you earn and spend each month.
- How much remains after all obligations.
- How much is already committed to future goals.
- How much is safely available for discretionary spending.
- Whether your current savings rate is sufficient for your goals.
- Whether future expenses create a cash-flow crunch.

Recurring transactions should be detected where possible, but the user must be able to review and correct classifications.

## 3.4 Financial dashboard

The home screen should answer the most important questions at a glance.

Illustrative dashboard

## Your financial overview

Net worth

# ₹X

Illustrative layout only — not a live calculation

Monthly surplus

## ₹X

After obligations

Outstanding debt

## ₹X

All tracked loans

Goals on track

## X of Y

Based on current plans

Financial resilience

## To assess

Based on coverage and liquidity

### Your next priorities

Build your emergency reserve

Calculate the reserve needed to cover essential expenses and EMIs if income stops.

Plan upcoming large expenses

Compare a planned purchase against the money needed for other goals.

Review long-term progress

Check whether retirement and education savings are projected to meet their targets.

The dashboard must be data-driven. It should not display a reassuring green indicator when essential data is missing or a critical risk has not been assessed.

The app should let you drill down into every number to see the underlying accounts, assumptions, and calculation.

# 4. The financial planning engine

This is the heart of the product.

A typical finance app tells you what happened. Your app should explain what is likely to happen, what you can change, and which decisions produce the best outcome.

## 4.1 Financial projection engine

The app should project the user's financial position over configurable horizons: 1, 3, 5, 10, 20, and 30 years.

It should model:

- Salary increases, promotions, bonuses, and employment changes.
- Monthly savings and investment contributions.
- EPF contributions, interest, and applicable contribution rules.
- NPS contributions, investment returns, and applicable withdrawal rules.
- Investment growth, fees, taxes, and inflation.
- Loan amortization, interest rates, EMIs, and prepayments.
- Property appreciation, rental yield, vacancy, maintenance, and selling costs.
- Insurance premiums and major known future expenses.
- Children's education and other family goals.
- Retirement income, expenses, and withdrawal needs.

Every projection must be based on explicit assumptions. Unknown future events should not be presented as certain outcomes.

### Illustrative projection example

Suppose your current EPF balance is ₹30 lakh, your monthly total contribution is ₹40,000, and the assumed annual return is 8%.

Example only · Constant contributions and return. Convention: the 8% annual return is converted to an effective monthly rate of (1.08)^(1/12) − 1 (≈ 0.6434% per month); each month the balance earns that rate and the ₹40,000 contribution is added at the end of the month.

After 5 years (60 months)

# ₹73.26 lakh

After 10 years (120 months)

# ₹1.368 crore

| Convention | Monthly rate | After 5 years | After 10 years |
| --- | --- | --- | --- |
| Effective monthly rate, end-of-month contributions (used above) | (1.08)^(1/12) − 1 | ≈ ₹73.26 lakh | ≈ ₹1.368 crore |
| Nominal monthly rate r/12, end-of-month contributions | 0.08 / 12 | ≈ ₹74.09 lakh | ≈ ₹1.398 crore |

An implementation must state which convention it uses; the two conventions give different results for the same inputs, as the table shows.

These rounded estimates exclude changes in contributions, salary-based contribution rules, taxes, and actual EPF rate changes. They are not guaranteed balances.

The app should also show future values in today's purchasing power.

For instance, ₹1 crore received 20 years from now will buy less than ₹1 crore buys today. That distinction is crucial when estimating education costs and retirement needs.

## 4.2 Multiple scenarios

Every projection should support three baseline scenarios.

Conservative scenario

Lower income growth or investment returns, higher expenses, and possible financial shocks.

Expected scenario

Reasonable assumptions based on the user's history, documented financial inputs, and explicitly chosen future rates.

Optimistic scenario

Favorable outcomes that help illustrate potential upside, without treating it as the expected result.

The user must be able to edit the assumptions and immediately recalculate the outcomes.

The system should show ranges where appropriate rather than suggest it knows the exact value of someone's wealth 20 years in the future.

## 4.3 Life-event simulation

The user should be able to model a decision before committing money.

Examples:

- Buy a car worth ₹15 lakh in 2027.
- Take a ₹2 lakh international vacation.
- Prepay ₹10 lakh on the home loan.
- Increase retirement contributions by ₹15,000 a month.
- Purchase an additional property.
- Take a six-month career break.
- Change jobs and increase salary by 20%.
- Have another child and add the expected costs.
- Retire at 45 instead of 60.

Each simulation should show the change in cash flow, liquidity, debt, net worth, goal completion dates, and retirement readiness.

The app should support saving multiple scenarios and comparing them side by side.

# 5. Goal planning and milestone tracking

Goals are first-class entities, not just notes or reminders.

Each goal should contain:

| Field                | Description                                       |
| -------------------- | ------------------------------------------------- |
| Name                 | Car, home, education, travel, retirement, etc.    |
| Target amount        | Expected cost or required corpus                  |
| Target date          | When the money is needed                          |
| Priority             | Essential, important, or discretionary            |
| Current allocation   | Money already set aside                           |
| Funding strategy     | Savings, investments, cash flow, or a combination |
| Inflation assumption | Used to calculate future cost                     |
| Progress             | Current position versus target                    |
| Dependencies         | Related debts, income, or other goals             |
| Status               | On track, at risk, delayed, or completed          |

### Goal-planning workflow

1. Define the goal. Example: buy a car in two years for an estimated ₹15 lakh.
2. Calculate the future cost. Account for inflation and relevant fees.
3. Calculate the funding gap. Subtract the money already earmarked for the goal.
4. Find a feasible strategy. Determine the required monthly savings, likely funding source, and any trade-offs.
5. Check competing goals. Ensure the purchase doesn't undermine emergency savings, debt obligations, education funding, or retirement plans.
6. Track progress. Update the plan when income, expenses, balances, or target dates change.

### Example: Can I afford the car?

The app should not simply answer yes or no.

A useful answer would look like this:

> Based on your current income, savings, and home loan, buying this car in 2027 appears feasible under the expected scenario. However, paying the entire amount upfront would reduce your emergency reserve below your chosen target.
>
> You have three options: delay the purchase by six months, save a fixed amount every month, or make a partial down payment while maintaining a sufficient cash reserve.
>
> Here is how each option changes your cash balance, monthly obligations, education goal, and projected net worth.

The actual conclusion must be generated from the user's data and calculated scenarios, not from a canned answer.

# 6. Personalized recommendations

The app should provide a prioritized action plan, not a generic list of financial tips.

## 6.1 Areas it should evaluate

Financial safety

Emergency fund, income-loss scenarios, insurance gaps, liquidity, dependents, and debt obligations.

Debt strategy

Loan interest rates, prepayment choices, refinancing, repayment schedules, and the trade-off between debt reduction and investing.

Savings and investments

Monthly savings capacity, asset allocation, concentration risk, diversification, liquidity, tax treatment, and goal-specific investing.

Tax and retirement planning

Applicable tax regime, deductions, tax-efficient contributions, retirement corpus, withdrawal strategy, and future income requirements.

Lifestyle and goals

How much can be spent on travel, vehicles, hobbies, or other goals without compromising essential financial objectives.

## 6.2 Recommendation format

Every recommendation should include:

- What to do: a concrete action.
- Why it matters: the financial problem or opportunity.
- Expected impact: estimated effect on wealth, liquidity, or goal progress.
- Alternatives: other viable choices.
- Trade-offs: what the user gives up.
- Assumptions: the numbers and rules behind the recommendation.
- Confidence: how reliable the result is, based on the available information.
- Next step: a practical action the user can take.

Recommendations should be ranked by urgency, financial impact, and the time needed to act.

For example, an insurance gap affecting dependents is generally more urgent than optimizing a small investment expense. But the ranking must consider the user's actual circumstances.

## 6.3 Confidence and reassurance

One of the product's most important jobs is helping the user feel confident without giving false reassurance.

The app should distinguish between:

- Secure: the modeled goals are funded under the selected scenarios, and essential risks are adequately addressed.
- On track: the current plan appears feasible but depends on future income or returns.
- At risk: one or more important goals may fall short.
- Needs attention: an immediate liquidity, debt, insurance, or other critical issue needs review.
- Insufficient data: the app cannot yet make a reliable assessment.

These are planning assessments, not guarantees.

A user should be able to see exactly why the app reached a conclusion and what would change it.

# 7. Financial data ingestion and read-only account access

This is a critical part of the product. The objective is to build a reliable financial record without requiring the user to enter every number manually.

## 7.1 Data-source strategy

Use three methods, in this order of practical importance.

Method A — Document uploads

Payslips, EPF passbooks, bank statements, NPS statements, mutual fund statements, insurance schedules, loan statements, and tax documents.

Best starting point

Method B — Manual entry and corrections

For property valuations, private business ownership, family loans, cash, unlisted investments, and data that cannot be fetched electronically.

Method C — Authorized read-only integrations

Connect eligible financial institutions and official services using supported APIs, authorization flows, or permitted data-sharing mechanisms.

### India-specific integration plan

| Data source                 | Initial approach                   | Later integration                                           |
| --------------------------- | ---------------------------------- | ----------------------------------------------------------- |
| EPF / UAN                   | Upload passbook or statement       | EPFO SMS / email contribution messages (EPFO has no member API) |
| NPS                         | Upload statement or enter balance  | Units × the NPS Trust daily NAV                             |
| Bank accounts               | Import statements                  | Balances from the bank's own alert emails / SMS; Account Aggregator only through a regulated partner (see below) |
| Mutual funds                | Import consolidated statements     | Units × the AMFI daily NAV                                  |
| Stocks / ETFs               | Import broker statements           | Units × closing prices from exchange files the owner downloads; foreign shares at a price the owner enters |
| Home loans                  | Upload lender statement            | Lender integration, if offered                              |
| Insurance                   | Upload policy documents            | Insurer integration, if offered                             |
| Property / private business | Manual entry and valuation updates | Accounting or valuation integrations where available        |

The availability of any integration must be verified with the relevant institution and its current API and authorization requirements. EPFO and NPS providers expose no member API for personal applications.

Account Aggregator data can only be requested by a regulated, registered Financial Information User — not by an individual's own app — so it is not a data source for this product unless a regulated partner is used (an open question in [`README.md`](README.md#open-questions)). The app never scrapes internet banking or any other website and never stores bank or EPFO portal passwords. Exchange price files are never downloaded automatically (exchange terms forbid it). Live-data sources, the review queue, auto-apply and freshness are specified in the [Life OS Finance box spec](../../life-os/spec/boxes/finance.md#live-data).

## 7.2 How the import process should work

1. Collect. The user uploads a file or authorizes an eligible data source.
2. Extract. Document parsers and AI-assisted extraction identify balances, transactions, dates, interest rates, contributions, and other relevant fields.
3. Validate. The app checks dates, units, account identifiers, totals, and whether the figures reconcile with the source.
4. Normalize. Data is converted into a common internal format, irrespective of the original bank or document format.
5. Match. Existing assets and liabilities are matched to imported records to prevent duplicate accounts or balances.
6. Review. Ambiguous values are presented for user confirmation rather than silently accepted.
7. Update. The financial model is recalculated, and any material change to the plan is surfaced.

Every imported value should retain its source and the date it was observed. This allows the user to trace a projected number back to a real financial record.

## 7.3 Read-only security model

The first version must not have the ability to transfer funds, place orders, redeem investments, change beneficiaries, or modify account settings.

Prefer read-only scopes when the provider supports them. Store only the authorization material needed for the approved integration, encrypt it, and provide a way to revoke access.

Read-only must be a technical permission boundary, not merely an instruction to the AI.

For document imports, the app should also protect sensitive identifiers, remove unnecessary data from AI prompts, and provide retention and deletion controls.

# 8. AI architecture: how to make the advice trustworthy

The app should combine conventional financial software with an AI reasoning interface.

The LLM should interpret questions, explain calculations, compare scenarios, and help the user explore decisions. It should not independently invent or calculate authoritative financial balances in free-form prose.

## 8.1 Recommended architecture

User interface

Dashboard, goals, financial records, chat, scenarios

AI orchestration layer

Understand intent, retrieve relevant records, select tools, explain results

Financial engine

Net worth, projections, taxes, loans, affordability, goal calculations

Financial data store

Verified records, ownership, history, assumptions, source documents

Validation and privacy layer

Access control, source validation, audit logs, calculation checks, consent enforcement

## 8.2 Division of responsibility

| Component                    | Responsibility                                                                                      |
| ---------------------------- | --------------------------------------------------------------------------------------------------- |
| LLM                          | Understand natural language, explain trade-offs, ask clarifying questions, generate recommendations |
| Financial calculation engine | Calculate balances, projections, loan schedules, goal feasibility, and scenario comparisons         |
| Data layer                   | Store financial records, source evidence, assumptions, ownership, and historical snapshots          |
| Rules engine                 | Apply deterministic financial rules and configured planning constraints                             |
| Document processing          | Extract information from statements and identify uncertain fields                                   |
| Authorization layer          | Enforce access, consent, and read-only boundaries                                                   |
| Monitoring                   | Detect stale data, failed imports, calculation inconsistencies, and material plan changes           |

The LLM should request a calculation through a defined tool interface, receive structured results, and explain those results to the user.

### Example

User: "Can I afford a car for ₹15 lakh next year?"

The AI should:

1. Retrieve current cash, investments, monthly surplus, loans, and existing goals.
2. Ask for any missing material information, such as the target purchase date or whether a down payment is planned.
3. Run affordability calculations under several scenarios.
4. Compare the resulting cash reserve and goal progress against the user's chosen thresholds.
5. Explain the options, risks, and assumptions in plain language.

If a key balance is six months old, the system should flag that fact and explain how it affects the conclusion.

## 8.3 Prevent hallucinated financial advice

Implement these requirements from day one:

- Every displayed financial figure must come from a stored record or calculation result.
- Each material recommendation must identify its inputs and assumptions.
- The AI must not treat a missing value as zero.
- Conflicting records must be surfaced and reconciled.
- The system must distinguish actual balances from estimated future values.
- External financial facts, interest rates, tax rules, and product details must be verified against current authoritative sources before they are used for consequential recommendations.
- If the data is insufficient, the app must say so.
- Every recommendation should be reproducible from a saved snapshot of its inputs and calculation version.

# 9. Security, privacy, and financial-data ownership

Financial records are among the most sensitive data a user can provide. Security must be part of the initial design, not a later feature.

## Mandatory requirements

- Strong authentication and optional biometric unlock.
- Encryption in transit and at rest.
- Secure secret storage and short-lived access tokens where supported.
- Strict separation of account data by user.
- Access-controlled document storage.
- No unnecessary storage of full account numbers, passwords, PINs, or OTPs.
- No trading, payments, or financial account modifications in V1.
- Data export, deletion, and revocation of connected-account permissions.
- Audit logs for account access, imports, corrections, and recommendations.
- Backups, recovery procedures, and protection against unauthorized access.
- Clear disclosure of any external AI provider that processes financial data.

Where practical, sensitive account identifiers should be tokenized or masked. The system should minimize what is sent to an LLM and ensure uploaded documents cannot instruct the AI to override its security rules.

### Future family permissions

When the family version is introduced, each financial record should have an explicit owner and sharing policy.

For example:

- A person can see their own financial records.
- A spouse can share selected information for household planning.
- A joint property can be visible to authorized co-owners.
- A business record can be shared with designated participants.
- The family's collective view can show approved shared assets without exposing unrelated personal accounts.

The system must not infer permission merely from a family relationship.

# 10. Data model and extensibility

The data model should support the family version from the beginning, even though the first interface is personal.

The central design principle is to separate people, ownership, financial records, goals, and planning scenarios.

## 10.1 Core entities

| Entity               | Purpose                                                             |
| -------------------- | ------------------------------------------------------------------- |
| User                 | Login, preferences, and authentication                              |
| Person               | A real-world individual whose finances may be tracked               |
| Household            | A group of people coordinating household finances                   |
| Organization         | A family business or other legal entity                             |
| FinancialAccount     | A bank, investment, retirement, or other account                    |
| Asset                | Property, investments, cash, business interests, and other holdings |
| Liability            | Loans, credit balances, and other obligations                       |
| OwnershipInterest    | Who owns an asset and in what proportion                            |
| IncomeStream         | Salary, rent, business distributions, and other income              |
| Expense              | Recurring and one-time spending                                     |
| InsurancePolicy      | Coverage, premiums, insured parties, and policy terms               |
| FinancialGoal        | A target amount, date, and funding strategy                         |
| Scenario             | A proposed change to the user's financial plan                      |
| FinancialSnapshot    | A dated view of the user's financial position                       |
| DataSource           | The origin, timestamp, and verification status of a record          |
| Recommendation       | An actionable suggestion and its supporting calculations            |
| Consent / Permission | Who can access which data and for what purpose                      |

## 10.2 Ownership is not the same as visibility

Imagine a rental property worth ₹2 crore owned equally by two brothers.

The app should distinguish:

- Total property value: ₹2 crore.
- First brother's ownership: ₹1 crore.
- Second brother's ownership: ₹1 crore.
- Rental income: allocated according to the actual ownership or agreed distribution arrangement.
- Outstanding property loan: attributed to the actual borrower or liability owners.
- Who can view the record: controlled separately through permissions.

The same principle applies to businesses, inherited land, joint investments, and family loans.

Important: The app must not automatically equate ownership percentages with liability shares, cash distributions, or legal entitlement. Those arrangements may differ and must be recorded separately.

## 10.3 Avoid double-counting

Suppose you own shares in a business that also owns a building.

If the app counts the full building value and then adds the entire business value, it may overstate your wealth.

The model must distinguish between:

- Direct asset ownership.
- Ownership in an entity.
- Assets already included in an entity's valuation.
- Personal versus business liabilities.
- Gross versus net valuations.

For family reporting, provide two views:

1. Individual net worth: the person's attributable assets minus their attributable liabilities.
2. Consolidated family wealth: the family's eligible assets and liabilities, with internal transfers and overlapping ownership removed.

The consolidation engine should be tested carefully before the family version is released.

# 11. User experience and navigation

The app should feel like a personal financial workspace rather than a complicated accounting system.

Overview

Net worth, monthly cash flow, financial resilience, and priorities.

My finances

Accounts, investments, property, loans, income, expenses, and insurance.

Goals

Milestones, funding plans, deadlines, and progress.

Future and scenarios

Long-term projections, retirement, what-if analysis, and comparisons.

Ask your AI CFO

Ask questions, investigate risks, understand recommendations, and explore financial decisions.

### The conversational interface

Chat should complement the structured interface, not replace it.

For example, when the user asks, "What if I increase my monthly investments by ₹20,000?", the response should contain:

- A short explanation.
- The revised projection.
- The difference from the current plan.
- The effect on other goals.
- A breakdown of the assumptions.
- An option to save the scenario.

The user should be able to move directly from a recommendation to the relevant financial record or scenario.

# 12. Recommended technology stack

For a personal-first app with sophisticated financial calculations and future multi-user support, I would use a conventional, modular application architecture rather than start with a complex multi-agent system.

The specific choices below are recommendations, not hard requirements. They are superseded for hosting by the decided local-first approach (the owner's own devices and home server, end-to-end encrypted sync, no cloud backend holding plaintext) — see the [Life OS tech stack](../../life-os/spec/README.md#tech-stack-suggested-not-mandatory); the architectural principles below still apply.

MOBILE APP

Flutter

A good choice if the primary experience is on Android and iOS, with a consistent cross-platform interface.

BACKEND

Python + FastAPI

Suitable for financial calculations, data processing, document extraction, AI orchestration, and typed APIs.

DATABASE

PostgreSQL

Strong relational modeling for financial records, ownership, transactions, permissions, goals, and historical snapshots.

DOCUMENT STORAGE

Encrypted private object storage

For uploaded statements and supporting evidence, with access-controlled retrieval and configurable retention.

AI LAYER

LLM with structured tool calling

Used for question understanding, explanations, retrieval, and decision support. Financial calculations remain in deterministic services.

CALCULATION AND TESTING

Dedicated financial domain library

Independently tested functions for loan schedules, compounding, inflation, goal funding, tax estimates, and scenario comparisons.

## Architectural principles

1. Keep the financial engine independent of the LLM provider.
2. Keep financial data independent of the mobile interface.
3. Version calculation logic and assumptions.
4. Use automated tests for financial formulas and reconciliation.
5. Use migrations and explicit schemas for data changes.
6. Enforce access control in the backend, not just the UI.
7. Design integrations as replaceable adapters.
8. Use background jobs for imports, periodic refreshes, and alerts.
9. Start with a modular monolith; introduce distributed services only when necessary.
10. Keep a complete audit trail of material changes to financial inputs and recommendations.

This makes it possible to change the mobile app, AI provider, or data source without rebuilding the entire product.

# 13. Implementation roadmap

The initial target should be a useful, trustworthy personal financial planning system, not a fully automated financial institution.

The estimates below are planning ranges for a solo developer or small team; actual effort depends on integration availability, security requirements, and product polish.

### Phase 1

2–3 weeks

Foundation and financial inventory

- Define the financial data model.
- Add assets, liabilities, income, expenses, and insurance.
- Build manual entry and editing.
- Calculate net worth and monthly cash flow.
- Establish secure storage and authentication.

### Phase 2

2–3 weeks

Document ingestion

- Upload statements and payslips.
- Extract structured financial records.
- Add source attribution and verification.
- Prevent duplicate records.
- Support corrections and historical balances.

### Phase 3

3–4 weeks

Financial projections and goals

- Implement loan amortization and investment projections.
- Add inflation-adjusted goals.
- Build milestone tracking.
- Add conservative, expected, and optimistic scenarios.
- Validate the calculation engine against independent test cases.

### Phase 4

2–4 weeks

AI CFO interface

- Natural-language financial questions.
- Structured calculation tools.
- Recommendation prioritization.
- Scenario comparison and explanations.
- Missing-data warnings and traceability.

### Phase 5

2–4+ weeks

Hardening and personal use

- Test security, backups, and recovery.
- Test projections against known examples.
- Refine the dashboard and onboarding.
- Add data freshness indicators.
- Test with your own financial records.

Estimated initial build: approximately 11–18 weeks for a capable solo developer working consistently, potentially longer with limited experience or significant integration work. A small team may shorten calendar time, but secure financial integrations and reliable planning logic still require careful validation.

External account integrations should be a separate workstream because availability and authorization are outside the app's control.

# 14. What V1 must include — and what it must not

The biggest product risk is trying to build everything at once.

## V1 must include

- Complete manual financial inventory.
- Upload and parse common financial documents.
- Track income, expenses, and liabilities.
- Calculate net worth and monthly surplus.
- Project EPF, NPS, investments, loans, and overall wealth.
- Create goals and track milestones.
- Simulate major purchases and other financial decisions.
- Generate personalized, explainable recommendations.
- Answer natural-language questions using the financial engine.
- Show assumptions, data sources, and stale information.
- Protect sensitive data and enforce read-only behavior.
- Export data and recover from backups.

## Explicitly defer

- Real-time integrations with every financial institution.
- Automatic trading, payments, or investment execution.
- Full tax-return filing and legally binding tax advice.
- Automatic property valuations.
- Detailed accounting for complex private businesses.
- Multi-user family sharing and permissions UI.
- Family-wide investment optimization.
- Complex estate planning and inheritance workflows.
- Autonomous AI agents that take financial actions.

The app can still store business ownership and shared-property details in a basic form. Advanced consolidation and collaboration should come later.

# 15. Success metrics

The app should be judged by whether it improves financial decision-making, not by how many AI conversations it supports.

| Metric                      | What success looks like                                               |
| --------------------------- | --------------------------------------------------------------------- |
| Financial completeness      | The user knows which important records are missing                    |
| Data accuracy               | Imported and calculated values reconcile with source records          |
| Projection correctness      | Calculation results pass independent tests                            |
| Recommendation traceability | Every material suggestion can be explained and reproduced             |
| Goal clarity                | The user can see funding gaps and required monthly savings            |
| Decision usefulness         | The user can compare options before committing money                  |
| Data freshness              | Important balances are current or explicitly marked stale             |
| Security                    | Unauthorized access is prevented and access is auditable              |
| User confidence             | The user understands risks, trade-offs, and the basis for reassurance |

For the initial version, I would prioritize financial accuracy, goal feasibility, and decision usefulness above engagement metrics or the number of automated integrations.

# 16. Major risks and mitigations

Incorrect financial advice

Mitigation: deterministic calculations, independent tests, current-source verification, explicit assumptions, and uncertainty disclosures.

Incomplete or stale records

Mitigation: source dates, freshness indicators, reconciliation, missing-data checks, and conservative handling of uncertainty.

Exposure of sensitive information

Mitigation: encryption, least-privilege access, secure authorization, masked identifiers, and strict data isolation.

Double-counted family wealth

Mitigation: explicit ownership interests, entity-level accounting, consolidation rules, and separation of legal ownership from visibility permissions.

Unreliable integrations

Mitigation: provider adapters, documented fallbacks, manual imports, and no dependency on unsupported APIs.

Regulatory and tax issues

Mitigation: review applicable Indian financial-data, privacy, tax, and investment-advisory requirements before offering regulated services or distributing the product commercially.

If the app is eventually offered to other users in India, the distinction between financial education, personalized planning, investment advice, and regulated financial services must be reviewed carefully. An AI disclaimer alone does not eliminate regulatory obligations.

# 17. Example of the finished experience

Imagine opening the app in January and asking:

"I want to plan the next five years. Can I comfortably manage my home loan, buy a car, take two vacations a year, and still secure my child's education and my retirement?"

The app should:

1. Establish your current financial position.
2. Check the freshness and completeness of your financial data.
3. Project income, expenses, debt repayment, retirement contributions, and investment growth.
4. Estimate future education costs and retirement requirements.
5. Model the car purchase and annual vacations.
6. Compare scenarios and identify any conflicts between goals.
7. Recommend a practical savings and spending strategy.
8. Show what happens if income growth is lower, expenses rise, or a financial emergency occurs.
9. Track actual progress against the plan and revise it as circumstances change.

The result should be a financial plan you can understand, challenge, and update — not just a dashboard full of numbers.

The app should also let you ask follow-up questions such as "What if I delay the car by one year?" and show the updated calculations immediately.

# 18. My final recommendation

I would build this product around three core capabilities:

1\. A trusted financial record

A complete, source-backed understanding of your financial position, including assets, debts, income, expenses, insurance, and obligations.

2\. A financial simulation engine

A reliable way to model your future, test decisions, track milestones, and understand the trade-offs between different plans.

3\. An AI financial guide

A conversational interface that understands your circumstances, explains your options, and recommends what to do next using verified data and calculated outcomes.

These three components will provide far more lasting value than starting with a chatbot and adding financial calculations later.

The family version then becomes a natural extension: multiple people, separate financial records, shared assets, business ownership, household goals, and consolidated wealth planning — all built on the same underlying foundation.

The north star: You should never have to reconstruct your financial life from multiple apps, spreadsheets, statements, and conversations whenever you need to make an important decision.

Your AI CFO should already understand your position, explain what matters, show the likely consequences of your choices, and help you move toward the future you want.