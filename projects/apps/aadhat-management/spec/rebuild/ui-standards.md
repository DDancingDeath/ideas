# UI standards — rebuild

> **The app must look and feel like a shipped, production-grade product
> — not a prototype.** The v1 app
> ([`AadhatManagementApp`](https://github.com/DDancingDeath/AadhatManagementApp))
> is the **floor, not the ceiling**: the rebuild's UI must be at least
> as polished as v1 and should exceed it. "It works and the tests
> pass" is necessary but **not** sufficient — an unpolished, default-
> styled, POC-looking screen is a defect, the same as a wrong number.

This document is the contract for what "the UI is done" means. It sits
alongside [`quality-bar.md`](./quality-bar.md) (which governs test
quality), [`ergonomics.md`](./ergonomics.md) (shop-floor constraints),
and [`localization.md`](./localization.md) (the Hindi/English language
system). Where this and the spec disagree, the spec wins — flag it.

## Non-negotiables

1. **Production, not POC.** No browser-default form controls, no
   unstyled stacks of inputs, no "good enough for a demo". Every
   screen is designed, not just assembled.
2. **A real design system, single-sourced.** One set of design tokens
   (below) defined once (CSS custom properties / a tokens module) and
   used everywhere. No ad-hoc hex codes or one-off paddings sprinkled
   through components.
3. **A reusable component set.** Buttons, inputs, selects, cards, list
   rows, tables, money display, status chips, the app header and the
   navigation are a consistent, shared library — not re-styled
   per-screen. A control looks and behaves the same everywhere.
4. **Mobile-first, one-handed, shop-floor.** Designed for a phone held
   in one hand in bright light (see `ergonomics.md`): large targets,
   thumb-reachable primary actions, high contrast, big legible money.
   It must also be usable (not just "not broken") on tablet/desktop.
5. **Hindi-first and fully localizable.** The layout must not assume
   English text widths and must render Devanagari well; every
   user-facing string comes from the message catalog
   (`localization.md`). The whole UI flips to Hindi from one toggle.
6. **Trust is the brand.** Money is unambiguous and prominent
   (tabular figures, clear currency). State is instantly legible:
   saved, pending, warning, error, and *cash short / over* each have a
   distinct, consistent visual treatment.

## Design tokens (single source of truth)

A tokens layer defines, at minimum:

- **Color** — a primary with light/dark variants, background, surface,
  border, text + muted text, and semantic `success` / `warning` /
  `danger` each with a matching subtle background. Documented hex
  values; WCAG-AA contrast for body text and on-primary text.
- **Typography** — a type scale (display / heading / body / caption
  with weights) and a font stack that includes a high-quality
  **Devanagari**-capable family. `tabular-nums` for all money and
  quantity figures.
- **Spacing** — a consistent scale (e.g. 4 / 8 / 12 / 16 / 24 …); no
  magic numbers.
- **Radii, elevation/shadow, and motion** — a small set of radii, an
  elevation ramp, and standard durations/easings for transitions.

## Navigation

- One clear, conventional mobile pattern for the app's destinations —
  e.g. a **bottom navigation bar** of 4–5 primary destinations plus a
  **"More" sheet** for the rest, or a pattern of equal quality. Not a
  cramped horizontal scroll of nine text tabs.
- The active destination is unmistakable. Tab switches are instant
  (< 100 ms, per `quality-bar.md` §9) and never drop input.
- Destinations use the **canonical names** from `localization.md`
  (which adopts the v1 app's established terminology) — never invented
  labels.

## Component quality bar

Every component ships with **all of its states designed**, not just
the happy path:

- **Buttons** — primary / secondary / destructive; default, hover,
  active, **disabled**, and busy/loading. Min target 44×44.
- **Inputs / selects** — label, placeholder, focus ring, **error**
  state with message, and disabled. Numeric inputs are touch-friendly.
- **Cards / list rows / tables** — consistent padding, dividers,
  empty-row handling, and a clear visual hierarchy.
- **Money display** — a single shared treatment: currency symbol,
  tabular figures, sign/colour for credit vs debit, large where it's
  the headline (bill total, net worth, cash expected).
- **Status chips / banners** — saved (success), advisory (warning),
  error (danger), and the cash short/over states — one consistent
  vocabulary across screens.
- **Empty, loading, and error states** — every list/screen has a
  designed empty state ("No dues 🎉", "Not enough data yet"), a
  loading affordance (skeleton/spinner, never a blank flash), and a
  graceful error state. A blank screen is a bug.

## Polish that separates production from POC

- **Micro-interactions** — pressed-state feedback on tap, smooth (not
  janky) screen/tab transitions, a subtle confirmation when a bill
  saves.
- **Depth & rhythm** — deliberate elevation, consistent spacing rhythm,
  alignment; nothing looks like raw HTML.
- **Considered empty/first-run** — the app on day one (no items, no
  bills) looks intentional and guides the next action, not broken.

## Accessibility (in scope for v2.0)

Per `quality-bar.md` §12: keyboard/focus reachable, touch targets
≥ 44×44, WCAG-AA contrast, screen-reader labels on primary actions.
Because labels switch language, controls are keyed by `data-testid`
(not visible text) for tests — see `quality-bar.md` §7.

## Definition of UI done

A screen is done when:

1. It uses **only** design-system tokens and shared components.
2. **Every state** is designed: empty, loading, error, disabled,
   success, and the relevant warning/danger.
3. It is **responsive** — correct at a 360 dp phone width and still
   usable at tablet/desktop.
4. All strings come from the **message catalog**; it renders correctly
   in **both** English and Hindi, with Devanagari fitting the layout.
5. It is **accessible** (targets, contrast, focus, labels) and every
   interactive control has a `data-testid`.
6. It matches or exceeds the **v1 app's** polish for the same screen.
7. Visual-regression snapshots exist for both language modes
   (`quality-bar.md` §8).

## What is forbidden

- Default/unstyled browser controls shipped as final UI.
- Per-screen one-off colours, spacings, or component restyles that
  diverge from the design system.
- Hardcoded user-facing strings in components (breaks localization).
- A screen with an undesigned empty/loading/error state.
- Shipping a screen that looks worse than its v1 counterpart.

## Recent changes

- _2026-06-18_ · File created. Establishes the production-grade UI bar
  the owner asked for ("it has to be production kind, not POC kind"),
  with the v1 app as the floor to beat: a single-sourced design-token
  system, a reusable component set, a real mobile navigation pattern,
  an all-states component quality bar (incl. empty/loading/error),
  Hindi-first localizable layout, and a UI definition-of-done. Cross-
  references `quality-bar.md` (tests), `ergonomics.md` (shop floor),
  and the new `localization.md`.
