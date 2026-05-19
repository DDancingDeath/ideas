# Build prompt — assistant-inbox-triage

> ⚠️ **Do not hand this to an agent yet.** The open decisions in
> `../README.md` ("Open decisions") and `../idea.md` ("Open questions")
> need owner answers first. Once those are answered, fill in the bracketed
> placeholders below and proceed.

---

You are building **assistant-inbox-triage**, a personal Microsoft-internal
inbox-triage assistant that ranks my mail / Teams mentions / ADO PRs /
ADO bugs into one list with drafted actions. Everything you need is in
this folder.

## Step 0 — Confirm with the user

Do not start writing code until you have explicit answers to:

1. Surface: Teams self-chat Adaptive Card / CLI digest / Electron tray
   app / something else?
2. Runtime: Python 3.11 or Node 20?
3. LLM: which internal Azure OpenAI endpoint + deployment name?
4. AAD app: is there an existing app registration we can reuse, or does
   the user need to create one?
5. Are we shipping focus-time / OOF awareness in MVP or punting?

## Step 1 — Load context

1. `../README.md` — narrative entry point.
2. `../idea.md` — vision, target users, success criteria, non-goals.
3. `../spec/README.md` — placeholder spec; lists what needs to be
   covered when the spec is written.
4. `../plan/README.md` — current status + risks.

## Step 2 — Walking skeleton (no LLM yet)

1. Scaffold project in a new directory or repo (do NOT modify this
   `projects/assistant-inbox-triage/` folder; this repo stays docs-only).
2. MSAL Public Client login flow. Token cache in Windows Credential
   Manager.
3. Pull *only* these two sources into local SQLite:
   - Microsoft Graph: `/me/chats/getAllMessages` filtered to unread
     mentions of me.
   - ADO REST: `/git/pullrequests?reviewerId=me`.
4. CLI command that prints a table of unread items, sorted by age.
5. Smoke test: run it manually, see real items.

## Step 3 — Triage pass

1. Add Azure OpenAI client (internal endpoint).
2. For each item, generate an urgency score (1-5) and a one-sentence
   "why this matters" using a system prompt that loads my role
   context.
3. Persist score + reason in SQLite. Show them in the CLI output.

## Step 4 — Draft generation (PR comments only at first)

1. For each PR in the top-5, fetch the diff and a brief diff summary.
2. Generate a draft review comment (questions to ask, not approvals).
3. Surface in CLI with `[d]raft` and `[s]kip` keys. Never auto-post.

## Step 5 — Mail + bugs

1. Add `/me/messages` (delta query).
2. Add ADO WIQL query for bugs assigned/cc'd to me.
3. Re-rank across all four sources together.

## Step 6 — The chosen surface

Implement whichever surface the user picked in Step 0. CLI is the
fallback if undecided.

## Quality bar

- Never auto-sends anything. **Hard rule.**
- All secrets in Windows Credential Manager, not `.env`.
- Delta queries everywhere — no full mailbox scans.
- Local SQLite only; no corp data uploaded anywhere.
- Telemetry is local-only and opt-out.

## What you must NOT do

- Don't use public OpenAI or any third-party LLM SaaS.
- Don't auto-send, auto-approve, or auto-close anything.
- Don't ship without an audit of existing internal tools first.
- Don't expand scope to calendar / docs / SharePoint until MVP works on
  the four sources.
