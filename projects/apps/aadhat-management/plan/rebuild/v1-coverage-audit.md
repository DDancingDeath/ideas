# v1 → v2 feature coverage audit

> Does the spec cover everything the live app does? Audited by reading all of
> `AadhatManagementApp` `www/js/` (93 files, ~29 000 lines) against
> `spec/capabilities.md`, `spec/page-specs/` and `spec/rebuild/`.
>
> **Scope: features only.** Formula and calculation disagreements were also
> found and are being reviewed separately.
>
> Audited at the v1 commit of 2026-06-06. Functionality was judged by what
> exists in the code, not by what currently runs — a broken or unreachable
> feature still counts as something the shop may expect back.

## Where v1 is a reference, and where it is not

The owner's assessment is that **Stock, Finance, Analytics and Reports do not
work well in v1.** That makes parity the wrong goal for those four pages:
matching them would reproduce behaviour nobody trusts.

| Page group | v1 status | What v2 should do |
| --- | --- | --- |
| Billing (purchase + retail), Wholesale, Items, Expenses, Outstanding, Cash sessions, Auth, Admin, History | Works; used daily | **Parity matters.** A missing affordance here is a real regression |
| **Stock, Finance, Analytics, Reports** | Does not work well | **Design fresh from requirements.** Use v1 only to learn which questions the owner asks — never as a behavioural contract |

This audit splits along that line. Section A is parity work. Section B lists
what v1 *attempts* on the four weak pages: useful as requirements input,
explicitly not a spec to copy.

---

## A. Parity gaps — working v1 features the spec does not cover

Ordered by cost to the shop.

| # | Feature | Where in v1 | Why it matters |
| --- | --- | --- | --- |
| A1 | **Drawer reconciliation** — counted closing cash vs expected, and what happens on a mismatch | `cash-management.js` | `16-cash-management.md` defines `closingBalance = runningBalance` only: no counted amount, no mismatch, no tolerance, no resolution. Catching a drawer mismatch is one of the stated reasons for the rebuild |
| A2 | **Cash deposits** within a session | `cash-management.js:1163-1181` | Money leaving the drawer for the bank is unmodelled, so a session cannot balance |
| A3 | **Opening and closing notes** on a session | `cash-management.js:1210-1213` | Where the owner records why a day was odd |
| A4 | **Retail oversell confirmation** — warn before saving a sale exceeding stock | `retail-sale.js:440-479` | v1 stops the cashier mid-sale. Without it, negative stock appears silently |
| A5 | **Print-comments flag** — whether bill comments appear on the printed slip | `purchase.js:480-500`, `retail-sale.js:469-490` | Distinct from whether comments are stored. Decides what the customer physically receives |
| A6 | **Bill line edit and delete before save** | `purchase.js:295-333`, `retail-sale.js:292-347` | Correcting a mis-keyed item, rate or bag weight mid-bill. Routine at a counter |
| A7 | **Labor-charge settings absent from the config registry** — heavy-packet weight threshold (default 30 kg), labor rate per heavy packet (default ₹6), auto-labor default | `admin.js:94-116` | Owner-tunable in v1 and feeds invariant `M3`, where labor is *deducted* from supplier payment. `configuration.md` has 34 keys and none of these. `scope-boundaries.md:55` names them as shop-custom but no key exists |
| A8 | **Session history detail** — ordering, selecting a past session, its deposits, notes, reconciliation result | `cash-management.js:1080-1220` | Spec says "session history with details" without saying which details |
| A9 | **Wholesale stock validation at add-line as well as at save** | `wholesale-sales.js:90-142,229-330` | Two moments, two behaviours; the spec describes one and is ambiguous between warn and block |
| A10 | **Expense autocomplete and detail fields** | `miscellaneous.js:17-36,209-268` | Speeds repeat expense entry; `04-expenses.md` omits it |
| A11 | **History date-range filter** | `history.js` | Spec covers type filter and search, not date range |
| A12 | **Draft fidelity** — which fields a draft preserves (staged weights, lines, party, labor, comments) | `billing.js:355-438` | Spec says "save draft" without saying what a draft contains |
| A13 | **Item import compatibility** — legacy rate-column spellings, comma-separated rates, blank-row skipping | `items.js:363-455` | Decides whether the owner's existing spreadsheet still imports |
| A14 | **Contact-person field** in item export/import | `items.js` | Present in v1's file format; absent from `05-items.md` |

## B. The four weak pages — requirements input, not a contract

v1 attempts these. Treat them as evidence of what the owner wants to know, then
design the answer fresh.

| Page | What v1 attempts | Keep as a requirement? |
| --- | --- | --- |
| **Stock** | Staff masking — hides exact quantities above a threshold and hides estimated value from staff (`stock.js:147-190`) | **Yes — this is a policy, not a feature.** An owner/staff information boundary the v2 role matrix does not carry, and it survives any redesign |
| Stock | Hide zero-quantity rows (`stock.js`) | Probably — otherwise the page is mostly noise |
| Stock | Adjustment edge rules: clamping a "remove" at zero, meaning of the adjustment rate field, audit fields (`stock.js:419-509`) | Yes as requirements; v1's implementation is not a model |
| **Finance** | Period filter — week / month / year / all / custom (`finance.js:115-175`) | Owner decision. The spec states Finance has no period filtering (`09-finance.md:3-7`) — a removal never confirmed |
| Finance | Monthly profit chart (`finance.js:363-424`) | Owner decision; absent from `09-finance.md` |
| Finance | Custom asset / liability accounts (`finance.js:544-697`) | In active use, but `localStorage`-backed in v1 — needs a real model if kept |
| **Analytics** | Month summary, outstanding dues, prediction algorithm | Redesign. `rebuild/analytics.md` already specifies a fuller set |
| **Reports** | Overview totals, by item / party / time series, compare periods, CSV, PDF, Chart.js | Redesign. Keep the *report types* as the requirement; discard the implementation |

## C. Already declared out of scope — confirm the loss is intended

`scope-boundaries.md` names these. Listed so the decision is explicit rather
than inherited.

| # | Feature | Declared at | Note |
| --- | --- | --- | --- |
| C1 | Frequency-sorted item dropdown and "most-used" badges | `scope-boundaries.md:123-127` | v1 orders the billing dropdown by usage. Removing it makes every bill slower to key — and billing is a page that works |
| C2 | Bulk item import / export (Excel) | `:128-129` | The owner's catalogue currently lives in a spreadsheet |
| C3 | Custom finance accounts | `:130-131` | See Finance above |
| C4 | Native contact picker | `:132-133` | Fills supplier / customer names from the phone book |
| C5 | Orphan / unmatched stock buckets, including negatives | `:138-142` | v1's only visibility into legacy name-keyed stock discrepancies — though on a page that does not work well |

## D. Things that look like gaps but are not

- **Purchase has no page-spec.** It is a *mode* inside `02-billing.md`, which
  names `purchase.js` and specifies labor, heavy packets, weights and payment
  split throughout. Covered.
- **`configure.html` is an orphan template.** Its content moved into `admin.js`
  as the Configure tab; the template is dead markup. The *settings* it holds
  are real — see A7 — but the screen is not missing.
- **No print queue in v1.** v2 adds one. An improvement, not a gap.

## Recommendation

1. **A1–A7 into the spec before mockups begin** — each changes what a screen
   must show.
2. **A8–A14** get a `TODO(spec)` now, so none is rediscovered mid-build.
3. **Section B** feeds the Stock / Finance / Analytics / Reports redesign rather
   than parity work. The one item to carry across regardless is **staff stock
   masking** — an access policy that outlives the page it lives on.
4. **C1–C5** need one owner answer each: accept the loss, or move back into
   scope. C1 is the one worth arguing about — billing works today, and the
   frequency-sorted dropdown is what makes it fast.
