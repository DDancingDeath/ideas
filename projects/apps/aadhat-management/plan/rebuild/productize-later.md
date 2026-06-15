# Productize later

> Opinion. The owner wants to ship for the family shop first and
> generalize to other shops second. This document captures how to do
> step two without restarting.

## Principle

> **Shop-1 is the reference customer until at least one other shop
> is piloted.** Every "we'll need this for other shops" idea waits
> until shop-2 actually exists. Premature generalization is what
> turned every other small-shop POS into a bloated unusable mess.

The good news is the architecture in `spec/rebuild/architecture.md`
already makes productization cheap if you obey the boundary in
`spec/rebuild/scope-boundaries.md`:

- Anything in **Core** is a feature every shop gets.
- Anything in **Configurable** is a shop-profile knob.
- Anything in **Shop-custom** stays behind a `shopId === 'shop-1'`
  flag and gets evaluated for promotion the day shop-2 needs it.
- Anything **Not doing** stays not done.

## What "productizing" actually means

1. The same codebase serves N shops.
2. Each shop has its own data namespace (`shopId`), authorization
   boundary, configuration, and audit trail.
3. Onboarding a new shop is configuration, not code.
4. A shop's data is invisible to every other shop and to anyone
   except its owner-approved users.
5. Pricing / billing / support model — out of scope for this doc,
   but worth thinking about once shop-2 is real.

## Steps, in order

### Step 0 — ship v2.0 for shop-1 (and let it run)

Don't productize until v2.0 has been the family shop's only app
for a few weeks and the brother's Review Queue is calm. Run the
v1→v2 cutover with the dual-run window in
`plan/rebuild/roadmap.md` M12. If the brother is filing fewer
flags per week than in the equivalent v1 period, the foundation is
trustworthy enough to extend.

### Step 1 — write down what shop-1 assumed

Audit the codebase for hard-coded assumptions that other shops
won't share. Candidates:

- Item categories
- Bill template wording
- Default labor rates
- Cash mismatch tolerance
- Discount limits per role
- The exact set of expense categories
- Hindi spellings specific to a region

Each one moves into `shopProfile` and gets a default. The default
for shop-1 is the value that was hard-coded.

### Step 2 — design `shopId` if it isn't already there

If the M0 decision was to design `shopId` into every event from
day one, you're done. If not, this is the migration:

- Add `shopId` to the event schema (default `shop-1`).
- Add it to every projection query.
- Update security rules to filter by `shopId`.
- Add an invariant test that asserts cross-shop reads return
  empty.

### Step 3 — pilot one other shop

One. Not five. Ideally a shop the owner / brother can visit, watch
the staff use the app for a day, and observe what breaks.

The pilot is where you discover:

- Which "configurable" knobs are actually the wrong shape (e.g.
  shop-2 needs three discount limits, not two).
- Which "core" features are actually opinionated about shop-1's
  workflow.
- Which "shop-custom" features can promote into Configurable now
  that there are two examples.
- Which "not doing" items shop-2 considers must-have.

Resist the temptation to refactor mid-pilot. Take notes; refactor
after.

### Step 4 — productize for real (after the pilot)

- Move every "shop-custom" item that shop-2 also needs into
  Configurable.
- Add the onboarding flow: create shop, invite owner, set
  `shopProfile`, run an empty cash session, file the first bill.
- Add per-shop billing / support / metering only if there's a
  commercial intent.

### Step 5 — only then think about a third shop

Productization beyond two shops is a different problem (support
load, deploy story, telemetry per shop, feature requests from
shops with conflicting needs). Don't sign up shop-3 until shop-2
has run for at least a month.

## Things that will fight productization if you let them

- **UI strings inlined in components.** Move to a tiny lookup so
  per-shop label overrides are possible (e.g. the family's
  greeting on the printed bill).
- **Time zone + locale assumptions.** Shop-1 is `Asia/Kolkata` and
  `en-IN` / Hindi. Every "today" calculation must take the shop's
  configured timezone, not the device's.
- **Backend project naming.** If staying on Firebase, decide
  whether each shop gets its own Firebase project (clean isolation,
  more setup) or shares one with `shopId` partitioning (one
  project to operate, but rules must be airtight).
- **Audit log retention.** Shop-1 may be happy with 90 days; a
  second shop might need a year for compliance. Make retention a
  per-shop config from day one of productization.
- **Suspicion thresholds.** Built-in defaults are shop-1's values.
  Re-evaluate the defaults when shop-2 lands; what was "high" for
  the family might be normal elsewhere.

## What productization does not change

- The event-ledger model.
- The invariants.
- The bill-vs-print separation.
- The "UI never owns money math" rule.
- The agent roster.
- The quality bar.

If any of those would need to change to support shop-2, something
is wrong with that shop's request, not with the architecture.
