# Navigation and page inventory

> What screens Happa has, how they are reached, and who sees each one.
>
> [`ui-standards.md`](./ui-standards.md) §Navigation requires one conventional
> mobile pattern — a bottom bar of 4–5 primary destinations plus a More sheet,
> "not a cramped horizontal scroll of nine text tabs." v1 had 15 navigation
> destinations, so the inventory below reorganises rather than reduces.
>
> **Nothing the live app does is dropped.** Every v1 destination appears below,
> merged where two answered the same question. Additions are fine; losses are
> not.

## Inventory

Sixteen pages, plus Cash as a surface inside Today.

| Page | Reached from | Visible to |
| --- | --- | --- |
| **Auth** | pre-login | everyone |
| **Today** | bottom nav | all roles |
| **Cash** | inside Today; also deep-linkable | all roles |
| **Bill** | bottom nav | all roles |
| **Udhaar** (Outstanding) | bottom nav | receivable all roles; payable owner + manager |
| **Stock** | bottom nav | all roles, quantities masked for `staff` |
| **Items** | More | view all roles; edit owner + manager |
| **Expenses** | More | business all roles; personal owner only |
| **History** | More | all roles, scope by role |
| **Insights** | More | owner + manager |
| **Money** (Finance) | More | owner + manager |
| **Review Queue** | More, plus a badge on Today | owner + manager |
| **Settings** | More | all roles (device-level only) |
| **Ask** (chat) | More | all roles, answers scoped by role |
| **Admin** | More | **owner only** |
| **Diagnostics** | More | **owner only** |

Role visibility follows [`role-permission-matrix.md`](./role-permission-matrix.md).
A destination a role can never use is **absent from the navigation**, not
present and disabled.

## Bottom navigation

```
┌─────────────────────────────────┐
│                                 │
│           (screen)              │
│                                 │
├─────────────────────────────────┤
│  Today   Bill   Udhaar  Stock  ⋯│
└─────────────────────────────────┘
```

Five destinations, chosen by what the counter does all day:

- **Today** — the landing screen. What happened today, and the cash drawer.
- **Bill** — the daily loop. Purchase, retail and wholesale modes.
- **Udhaar** — who owes what, both directions. Checked constantly in a
  commission trade.
- **Stock** — "do we have it?", asked mid-sale with a customer waiting.
- **More** — everything else, as a sheet.

Destination labels use the canonical terms from
[`localization.md`](./localization.md), which adopts v1's established
vocabulary. Never invented labels.

## Parity with v1

Every one of v1's fifteen navigation destinations is present. Three were
reorganised, none dropped:

| v1 destination | Here |
| --- | --- |
| `day` | Today |
| `billing` | Bill (purchase + retail modes) |
| `wholesale-sales` | Bill (third mode) |
| `expenses` | Expenses |
| `items` | Items |
| `history` | History |
| `stock` | Stock |
| `due` | Udhaar |
| `finance` | Money |
| `reports` | Insights |
| `analytics` | Insights |
| `admin` | Admin (Configure / Users / Data tabs, as in v1) |
| `diagnostics` | Diagnostics |
| `settings` | Settings |
| `chat` | Ask |

Plus, not in v1's nav: **Auth** (pre-login), **Cash** (embedded in Today in v1
too), and **Review Queue** — genuinely new in v2.

**Ask is carried over, not deferred.** v1's assistant is a local rule-based
query interface with thirteen deterministic intents — stock by item, top
outstanding parties, profit for a period, today's sales — answered from state
with no model call, understanding Hindi item names. It is small, it works, and
the shop has it today. An LLM fallback remains out of scope for v2.0; the
deterministic intents are not.

## Two consolidations against v1

**Reports and Analytics merge into one surface, Insights.** Both answer *how is
the business doing over time*, both are being redesigned rather than carried
over, and between them they amount to one surface's content. Two pages over one
question is how they drift apart — the same reasoning that merged the
rate-history projection.

**Finance stays separate, as Money.** *Position* — what the shop owns and owes
right now — is a genuinely different question from *performance* over a period,
and conflating them is what makes v1's Finance page contradict itself.

Note that Insights and Money have a **slot** here but not yet **content**: both
are among the four pages awaiting the product questions in Happa's
`docs/ui/redesign-brief.md`.

## Cash is a surface, not a destination

Cash lives inside Today, as in v1, because opening and closing the drawer is
part of looking at the day rather than a separate errand. It is deep-linkable
so a notification or a Review Queue flag can jump straight to it.

## Open questions

- `TODO(spec, blocks: M7)` — Should wholesale be a third mode inside **Bill**,
  or its own bottom-nav destination? **Default:** a third mode. Billing already
  has a purchase/retail toggle, all three are "make a bill", and a separate tab
  costs one of only five slots. **The counter-argument is real and belongs to
  the owner:** this is an *aadhat* business, so wholesale is core revenue rather
  than an edge case. If the owner thinks in wholesale terms first it earns its
  own tab, and Stock moves to More.
- `TODO(spec, blocks: M9)` — Does Review Queue need a bottom-nav slot for the
  brother, or is a Today badge plus More enough? **Default:** badge plus More —
  he reviews once a day, not continuously.
- `TODO(spec, blocks: M6)` — Does the More sheet need search once it holds ten
  destinations? **Default:** no for v2.0; revisit if it grows.
