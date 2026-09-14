# Design system — decision brief

> Input for step 4 of Happa's build order. Once chosen, this becomes a row in
> [`decisions.md`](./decisions.md) with rationale and date, and this file can go.

## What is already settled

`decisions.md` has frozen the technical stack: **SvelteKit** (row 1), **Firebase**
(row 2), **pnpm** (row 3). The engine, read model and view models are built and
carry no UI-framework dependency, so the UI layer is a genuinely free choice on
top of a fixed foundation.

What is *not* settled is the **design language** — the owner's stated preference
is Fluent.

## The question is not which library

This is the part worth getting straight before arguing about aesthetics.

Neither candidate ships a component library you would actually use here:

- **Fluent** has a mature web implementation (Fluent UI), but it is React-first.
  There is no maintained Fluent component set for Svelte.
- **Material 3** has Web Components and excellent React bindings. The Svelte
  ports are thin and not reliably maintained.

So with SvelteKit already chosen, **either answer means building your own
component set**. And `ui-standards.md` independently requires exactly that —
"a reusable component set… buttons, inputs, selects, cards, list rows, tables,
money display, status chips, header and navigation… not re-styled per-screen."

The real question is therefore narrower and more answerable:

> **Which design language do we borrow tokens, metrics and interaction patterns
> from, while building our own small component set?**

## The case for Material 3

- **It is what the device speaks.** Happa is a Capacitor WebView on Android.
  Back gestures, scroll physics, ripple feedback, bottom navigation, the FAB
  position — Material matches what the OS and every other app on the phone do.
  Fluent will feel subtly foreign in a way users cannot name but do notice.
- **It is what the users already use.** Staff and the owner use WhatsApp,
  PhonePe, Khatabook. Their muscle memory is Material.
- **The spec already leans on it.** `ergonomics.md` sets the 48 dp minimum tap
  target and explicitly says "48 dp matches Android Material accessibility
  guidance". The accessibility metrics are already Material's.
- **Devanagari and density.** Material's type scale has been exercised heavily
  against Indic scripts; the line-height headroom Hindi needs is well trodden.

## The case for Fluent

- **You know it deeply.** Token discipline, layering, and the rigour Fluent
  brings to states and elevation are genuinely excellent, and familiarity means
  faster, more consistent decisions.
- **Its token model is the better-articulated one** — Fluent's thinking about
  semantic tokens over raw values is a good influence regardless of which
  language wins.
- **No second language to learn** while also learning Svelte and an
  event-sourced engine.

## Recommendation

**Material 3 for interaction and metrics; Fluent's discipline for how the token
layer is built; our own component set either way.**

Concretely:

- Take from **Material 3**: tap-target and spacing metrics, motion and gesture
  expectations, navigation patterns, elevation semantics, the type scale's
  handling of Devanagari.
- Take from **Fluent**: the habit of semantic tokens (`surface`, `on-surface`,
  `danger-subtle`) over raw palettes, and its rigour about defining every state
  rather than only the default.
- Build a small component set — roughly a dozen components, per
  `ui-standards.md` — rather than adopting any library wholesale.

The honest summary: **"Fluent" is a reasonable answer to "what should this feel
like to build", and a weak answer to "what should this feel like to use at an
Indian shop counter on Android."** Those can be separated, and separating them
gets you both.

## What this does not decide

- **Dark mode.** v1 has it; `settings.md` wireframe assumes it. Confirm it stays.
- **Charting.** Only needed once Reports and Analytics are redesigned — defer
  until the four product questions in Happa's `docs/ui/redesign-brief.md` are
  answered, so the chart library follows the charts rather than preceding them.
- **Icon set.** Follows the language chosen above.

## Why this matters more than it looks

The previous attempt's screens were rejected on quality. The lesson was not
"pick a better library" — it was that nobody had agreed the visual language,
the component set or what each screen should show before twelve of them were
produced in one run.

Two of those three are now fixed: the wireframes exist, and the component set
is specified. This decision is the third.
