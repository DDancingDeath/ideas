# Page specs — index

> **This directory is the contract.** When the owner says "page X is
> wrong", an agent reads the matching file here, finds the spec line
> that disagrees with the running app, and changes either the code or
> the spec (asking the owner first when both could be right).

## Sister documents

- `docs/CAPABILITIES.md` — descriptive ("what the code does today").
- `docs/REVIEW_ISSUES.md` — running list of known bugs.
- `AGENTS.md` — orientation for any agent landing in this repo.

## Shared math (single source of truth)

`www/js/utils/period-math.js` exports a `PeriodMath` static helper that
**Finance / Reports / Analytics all delegate to**. If two of those three
pages disagree on a number for the same definition, the bug is in
whichever caller bypassed `PeriodMath`. Spec authors: when in doubt
about which formula to write down, follow what `PeriodMath` does and
cite the method name.

| Concern | `PeriodMath` method |
|---|---|
| Date range from a chip name | `range(filter, customFrom?, customTo?)` |
| Filter records by date | `filter(records, range)` |
| Cash on hand right now | `cashOnHand()` |
| Stock value right now | `stockValue()` |
| Outstanding (receivable + payable) | `outstanding()` |
| Period revenue (retail+wholesale) | `totalSalesValue(range)` |
| Period purchases | `purchasesValue(range)` |
| Period business expenses | `expensesValue(range, 'business')` |
| Period cash-flow profit | `cashFlowProfit(range)` |
| Period realized profit (wholesale) | `wholesaleRealizedProfit(range)` |
| Period withdrawals | `withdrawalsValue(range)` |
| Cash / online / due split | `paymentSplit(records)` |

---

## How to use this directory

### If you are the **owner / reviewer**

1. Open the page file you're worried about.
2. Compare it line-by-line to the running app.
3. Tell the agent in plain English what doesn't match. Example:
   > "On `02-billing.md`, the spec says the labor field should be
   > deducted from the grand total on **purchase** bills. It's adding
   > it instead."
4. The agent will read that file, find the related code, and either
   fix the code to match the spec or update the spec and ask you to
   confirm.

### If you are an **AI agent**

1. Read the relevant page file **before touching code**.
2. The "Purpose" line and "Must NOT do" list are invariants — never
   break them.
3. The "Calculations / formulas" section is the math truth — when
   the user disputes a number on screen, this is the formula that
   should be running. If the code disagrees, change the code (or
   stop and ask).
4. If the user's report contradicts the spec, ask which side is right
   before writing code.
5. After any behavior change: update the matching page file in the
   same commit. Strikethrough never delete.

### Per-page file shape

Every page file uses this template:

```
# Page spec: <Label> (<tab id>)

## Purpose
1-2 lines. What this page exists to do (the invariant).

## Files
| Tab id | Template | Module(s) |

## Who can use it
Role gating (owner / admin / staff / pending).

## What the user sees (top → bottom)
Ordered list of visible UI sections.

## What the user can do
| Action | Effect | Writes to |

## Calculations / formulas
Every number on screen, in math notation. Source-file references.

## Data sources
AppState collections + Firestore paths read.

## Must NOT do
Invariants. Things the agent must never accidentally break.

## Known issues
Cross-linked to REVIEW_ISSUES.md.

## Example bug reports → what to change
Pre-written translations of plain-English complaints into code changes.
```

---

## Page index

| # | File | Tab id | Label | Owner-only? |
|---|---|---|---|---|
| 0 | [`00-auth.md`](./00-auth.md) | *(none)* | Login / Register | — |
| 1 | [`01-day.md`](./01-day.md) | `day` | Today | — |
| 2 | [`02-billing.md`](./02-billing.md) | `billing` | Billing | — |
| 3 | [`03-wholesale-sales.md`](./03-wholesale-sales.md) | `wholesale-sales` | Sales | — |
| 4 | [`04-expenses.md`](./04-expenses.md) | `expenses` | Expenses | — |
| 5 | [`05-items.md`](./05-items.md) | `items` | Items | — |
| 6 | [`06-history.md`](./06-history.md) | `history` | History | — |
| 7 | [`07-stock.md`](./07-stock.md) | `stock` | Stocks | — |
| 8 | [`08-due.md`](./08-due.md) | `due` | Outstanding | — |
| 9 | [`09-finance.md`](./09-finance.md) | `finance` | Finance | — |
| 10 | [`10-reports.md`](./10-reports.md) | `reports` | Reports | — |
| 11 | [`11-analytics.md`](./11-analytics.md) | `analytics` | Analytics | — |
| 12 | [`12-admin.md`](./12-admin.md) | `admin` | Admin | **yes** |
| 13 | [`13-diagnostics.md`](./13-diagnostics.md) | `diagnostics` | Diagnostics | **yes** |
| 14 | [`14-settings.md`](./14-settings.md) | `settings` | Settings | — |
| 15 | [`15-chat.md`](./15-chat.md) | `chat` | AI Assistant | — |
| 16 | [`16-cash-management.md`](./16-cash-management.md) | `cash-management` | Cash Management *(embedded in Today)* | — |

---

## Maintenance protocol

When you change behavior:

1. Find the page file.
2. Update the affected line(s). Strikethrough for removed behavior;
   never delete.
3. If the change addresses a Known Issue, also tick the matching row in
   `REVIEW_ISSUES.md`.
4. Commit message format:
   `feat(<page>): <summary> [PAGE_SPECS §<n>]` or
   `fix(<page>): <summary> [PAGE_SPECS §<n>]`.
5. The PR description should call out which page files changed.

When this directory disagrees with the running app:

1. Don't silently "fix" the code or the doc.
2. Stop and ask the owner which one is right.
3. Once the owner decides, change one or the other (or both) and commit
   with a clear reference to this conversation.
