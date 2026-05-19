# Idea — AadhatManagement

## One-liner

A bilingual (Hindi / English) business management app that lets a small
wholesale/retail shop run its daily operations — billing, sales, stock,
cash, outstanding, reports — from a phone or tablet, with Bluetooth thermal
printing and works-mostly-offline behavior.

## Problem

Small wholesale/retail shops in India typically run on paper ledgers plus
WhatsApp. The pain points:

- **No real-time view of stock** — owners discover shortages at sale time.
- **Outstanding (udhaar) is scattered** across notebooks and memory.
- **Cash drawer mismatches** at end-of-day with no audit trail.
- **Generic ERPs are too expensive, English-only, and Windows-bound.**
- **Family members + staff** all need *different* slices of the same data
  with different permissions, but most low-end POS apps have a single
  password shared by everyone.

## Target users

- **Primary**: The shop owner (and their immediate family co-running the
  business). Bilingual Hindi/English, comfortable with phones, not with
  desktop ERPs.
- **Secondary**: One or two trusted staff members who handle billing /
  cash but should not see margins or master settings.
- **Anti-users**: Multi-branch chains, enterprises, anyone needing GST
  filing automation (not in scope).

## What success looks like

- Owner can close the day in **under 5 minutes**: cash matches, stock looks
  right, outstanding list is current.
- Staff can issue a bill in **under 30 seconds** for a returning customer.
- Stock value, cash on hand, and outstanding are **always live and
  consistent** across the app — no "refresh", no stale dashboards.
- Owner trusts the audit log enough to give staff write access.

## Constraints

- **Mobile-first.** Most usage is on a 6" Android phone.
- **Offline-tolerant.** Patchy connectivity in the shop is the norm.
- **Free tier of Firebase** has to last — small write budget per day.
- **Thermal printer support** is non-negotiable for retail bills.
- **Hindi labels** alongside every English label, no separate locale toggle.

## Non-goals

- GST returns / e-invoicing automation.
- Multi-branch sync.
- Inventory forecasting / ML demand prediction.
- Customer-facing storefront / e-commerce.
- iOS app.
- Desktop-first UI.

## Inspiration / prior art

- Vyapar (closest commercial competitor) — too feature-heavy, weak Hindi.
- Khatabook / OkCredit — only solve the outstanding/khaata slice.
- Tally — desktop, accountant-oriented, doesn't fit a shop floor.

## Open questions

- [ ] Should we add a customer-facing "your khaata" link (read-only) sent
      via WhatsApp?
- [ ] Is there a path to per-item barcode / QR scanning that doesn't
      require a dedicated scanner?
- [ ] Long-term: replace the inline `window.app` bridge with a proper
      framework (Lit? Svelte?) — worth it, or premature?
