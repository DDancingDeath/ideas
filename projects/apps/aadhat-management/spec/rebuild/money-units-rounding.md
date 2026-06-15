# Money, units, and rounding — rebuild

> The arithmetic contract. Money is integer paise. Weight is
> integer milligrams. Rates are integer paise per kilogram. Line
> totals follow one formula, evaluated in one order, with one
> rounding rule. Discounts and labor are applied in a fixed
> order, audited in the event payload, never recomputed at read
> time. v1 → v2 conversion is a single multiply.
>
> Every screen, every printer template, every report, and every
> test derives every monetary number from this single helper.
> "Two screens disagree by a paisa" is a bug in this file or in
> the code that bypasses it.

## Why this doc exists

[`invariants.md`](./invariants.md) §Money declares the **laws**
(M1–M5) — totals must balance, money is integer paise, no
screen does its own period math. This doc declares the
**formulas** — how a line total is computed, in what order
discounts and labor are applied, how the result is rounded, and
how a v1 floating-point amount becomes a v2 integer.

Without this single source of truth, two implementations of
"bill total" drift by a paisa and one screen quietly disagrees
with the other — exactly the bug class v2 exists to eliminate.

## Atomic units

| Quantity | Atomic unit | Display unit | Conversion |
|---|---|---|---|
| Money | **paise** (integer) | ₹ (with 2 decimals) | `paise = ₹ × 100` |
| Weight | **milligrams** (integer, `mg`) | kg (with up to 3 decimals) | `mg = kg × 1_000_000` |
| Rate per unit weight | **paise per kilogram** (integer, `paisePerKg`) | ₹/kg (with up to 2 decimals) | `paisePerKg = ₹/kg × 100` |
| Count (pieces) | **integer** | pieces | none |
| Percentage (discount, tax) | **basis points** (integer, `bps`) | % (with up to 2 decimals) | `bps = % × 100` |

The atomic unit is what the event payload, the storage layer,
the projection, and every arithmetic helper see. Display units
exist only at the rendering boundary. The conversion direction
is **one-way at the boundary**: parse on input, format on
output; never re-store a display-string round-trip.

These choices are pinned in
[`../../plan/rebuild/decisions.md`](../../plan/rebuild/decisions.md)
rows 4 (`shopId`), 8 (integer milligrams) and are echoed here
so a single doc holds the full unit story.

## Rate representation

- A weight-priced item stores `ratePerKg` in `paisePerKg`.
- A piece-priced item stores `ratePerPiece` in `paise`.
- An item never carries both rate kinds at once. Changing the
  rate kind is an explicit migration on the item, not a per-bill
  override.
- The rate **at the time of the bill** is captured into the sale
  event's payload (per
  [`data-governance.md`](./data-governance.md) §Rate change
  history), so historical replay always reproduces the same
  totals even after a rate change.

## Line total formula

For a weight-priced line:

```
lineSubtotalPaise =
  round_half_even(
    (qtyMg × ratePerKgPaise) / 1_000_000
  )
```

For a piece-priced line:

```
lineSubtotalPaise = qtyPieces × ratePerPiecePaise
```

Then the line discount, if any:

```
lineDiscountPaise =
  round_half_even(lineSubtotalPaise × lineDiscountBps / 10_000)

lineTotalPaise = lineSubtotalPaise − lineDiscountPaise
```

Every line on a bill is computed independently. There is no
cross-line carry of rounding remainder; the carry-or-not
question is settled by **doing it on each line independently**
and accepting the per-line rounding. This matches v1 and avoids
the "subtotal screen and printed total disagree" class of bug.

## Bill total formula

```
itemsTotalPaise   = Σ lineTotalPaise across lines
billDiscountPaise = round_half_even(itemsTotalPaise × billDiscountBps / 10_000)
laborChargesPaise = (purchase only) sum of explicit labor lines
                                                                          ──── retail ────
grandTotalPaise   = itemsTotalPaise − billDiscountPaise                   (no labor)

                                                                          ─── wholesale / purchase ───
grandTotalPaise   = itemsTotalPaise − billDiscountPaise − laborChargesPaise
```

And the payment split:

```
cashPaise + onlinePaise + duePaise = grandTotalPaise        (M1 invariant)
```

The payment split is **provided** by the bill, not derived.
Staff fills `cash`, `online`, `due` and the domain validates
they sum to `grandTotal`. The form never auto-completes one
field to make the math work — it shows the residual and refuses
save until the user has filled it.

## Application order (canonical)

When the formula above is computed by the domain helper, the
order is fixed and visible:

1. Compute `lineSubtotalPaise` (qty × rate).
2. Apply `lineDiscountBps` → `lineTotalPaise`.
3. Sum lines → `itemsTotalPaise`.
4. Apply `billDiscountBps` → reduced items total.
5. Subtract `laborChargesPaise` (purchase / wholesale only).
6. Validate the payment split (`M1`).
7. Append the event with the resolved numbers in the payload.

The order is **never** "apply labor before bill discount" or
"apply bill discount before line discount" or any other
permutation. The fixed order is part of the contract: changing
it requires a `domainVersion` bump per
[`versioning-compatibility.md`](./versioning-compatibility.md).

## Rounding rule

- **Mode**: round-half-to-even ("banker's rounding"), to the
  nearest integer paisa.
- **Why**: removes the upward bias of half-up over long runs of
  bills; matches what most general-ledger engines do.
- **Where applied**: every step in the formula that produces a
  paisa result from a non-integer intermediate (line subtotal,
  discount amount).
- **Where forbidden**: in display formatters (display takes the
  already-integer paise and formats it).
- **Implementation note**: the helper takes integer inputs only.
  Intermediates that would overflow 53-bit safe integers (≈
  ₹9 × 10¹³) trigger an explicit error, not silent precision
  loss.

A v1 → v2 difference: v1 used `Math.round` (half-away-from-zero
on positives) on JavaScript floats. Per-bill, the result is
identical for all practical inputs; over a year's reports the
two rules can disagree by single-digit rupees on aggregates.
Reconciliation test `r1-v1-cash-flow-equality` (per
[`scenarios.md`](./scenarios.md)) pins the v1 numbers exactly
for the cutover period so the brother sees zero drift.

## Display formatting

- Indian digit grouping: `₹1,23,45,678.90` (two-two-two-three).
- Currency symbol leading, no space: `₹1,234.50`.
- Two decimal places always for money, even at integer amounts:
  `₹500.00`.
- Weights: up to three decimal places in kg, trailing zeros
  trimmed: `12.5 kg`, `0.075 kg`, `1.025 kg`.
- Percentages: up to two decimals, trailing zeros trimmed:
  `5%`, `7.5%`, `12.25%`.
- Hindi locale uses the same grouping and symbol; numerals are
  Western Arabic by default per
  [`ergonomics.md`](./ergonomics.md). Devanagari numerals are
  a per-shop setting.
- Negative amounts: `−₹100.00` with a minus sign (not
  parentheses); colour-coded red only when used as a financial
  loss indicator.

The formatter is one shared helper. Screens importing their own
`Intl.NumberFormat` invocation is a code-review reject.

## v1 → v2 import conversion

The cutover snapshot in
[`../../plan/rebuild/migration-cutover.md`](../../plan/rebuild/migration-cutover.md)
reads v1 records and writes v2 events. The conversion table:

| v1 field | v1 unit | v2 unit | Conversion |
|---|---|---|---|
| `amount`, `total`, `cash`, `online`, `due`, `discount` | `₹` as JS number (2 dp) | `paise` (integer) | `paise = Math.round(₹ × 100)` |
| `qty` for weight items | `kg` as JS number (2–3 dp) | `mg` (integer) | `mg = Math.round(kg × 1_000_000)` |
| `qty` for piece items | integer pieces | integer pieces | identity |
| `rate` per kg | `₹/kg` as JS number | `paisePerKg` (integer) | `paisePerKg = Math.round(₹/kg × 100)` |
| `rate` per piece | `₹/piece` as JS number | `paisePerPiece` (integer) | `paisePerPiece = Math.round(₹/piece × 100)` |
| Discount percentage | `%` as JS number (1 dp) | `bps` (integer) | `bps = Math.round(% × 100)` |
| Labor | `₹` as JS number | `paise` (integer) | `paise = Math.round(₹ × 100)` |

`Math.round` here is half-away-from-zero (the JS default) which
preserves v1's existing rounding for the snapshot. From the
cutover moment forward, the domain uses half-to-even. This
choice is deliberate: it keeps the imported numbers byte-equal
to v1's, while the new event log uses the more honest rule.

The migration tool **verifies** the round-trip: for every
imported bill, it re-renders the v2 grand total and asserts
equality with the v1 grand total it imported. A mismatch
aborts the import and surfaces the bill for owner review.

## Tests this spec requires

Per [`ci-contract.md`](./ci-contract.md) `unit` and
`invariant` jobs:

- `line-total-weight` — `qtyMg × ratePerKgPaise` over a fixture
  matrix (small, medium, large, on-rounding-boundary) returns
  the expected `lineSubtotalPaise` exactly.
- `line-total-piece` — pieces path.
- `line-discount-bps` — discount application gives expected
  result; on `0 bps` it is identity; on `10_000 bps` it is
  zero.
- `bill-total-retail` — formula across multiple lines with a
  bill-level discount.
- `bill-total-wholesale-with-labor` — formula with labor.
- `payment-split-m1` — sum of (cash, online, due) equals
  `grandTotal`; rejects bills that don't balance.
- `rounding-half-to-even-runs` — over 10 000 randomised bills,
  the aggregate matches the closed-form expectation within
  ±0 paise (no drift).
- `migration-roundtrip-equality` — imported v1 bills replay to
  the same total in v2.
- `display-format-grouping` — the Indian grouping renders
  correctly across magnitudes including ₹1, ₹100, ₹1,000,
  ₹10,000, ₹1,00,000, ₹1,00,00,000.
- `display-format-no-locale-drift` — formatter is hermetic; no
  test machine's locale influences output.

## Open items

- `TODO(spec)` — whether Devanagari numerals on display are
  per-shop or per-user. Default: per-shop (`shopProfile.locale.numerals`),
  with the per-user override added in v2.1 if requested.
- `TODO(spec)` — exact behaviour when a v1 import row has a
  `kg` value of more precision than 3 dp (e.g. `0.1234`).
  Default: round to mg, surface a warning row in the import
  report.
- `TODO(spec)` — should the helper expose a "preview" mode
  that returns rounded **and** unrounded values for the UI to
  show transparency? Default: no — UI shows only the rounded
  result. Revisit if the brother asks for it.

## Recent changes

- _2026-06-16_ · file created. Atomic units (paise / mg /
  paisePerKg / bps); rate representation (per-kg or
  per-piece, never both); line and bill total formulas with
  canonical application order; round-half-to-even rule;
  Indian display formatting; v1 → v2 conversion table with
  migration round-trip verification; required tests pinned to
  CI `unit` and `invariant` jobs.
