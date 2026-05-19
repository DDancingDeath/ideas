# Build prompt — agent-notes-reminders

> ⚠️ **Do not hand to an agent yet.** Resolve tenant + capture-surface
> + output-system decisions in `../README.md` first.

---

You are building **agent-notes-reminders**. Read `../README.md` and
`../idea.md`. Generate code in a separate directory / repo (not in
this `projects/` folder).

Walking skeleton:

1. Push-to-talk on the chosen surface (desktop hotkey for v1).
2. Whisper local for STT — pick model size based on CPU vs accuracy
   tradeoff.
3. Save raw transcript to local SQLite (`captures` table with FTS5).
4. CLI search command across captures.

No classification, no auto-routing, no output adapters in v1.

Quality bar:

- Capture latency (hotkey → "noted" feedback) < 3 s.
- STT runs fully on-device; nothing leaves the box at capture time.
- Search returns relevant hits within 200 ms on 10k captures.

Do NOT:

- Add wake-word support in v1.
- Push captures to any cloud service at capture time.
- Auto-create calendar events or send reminder mails until the user
  has confirmed the output-adapter design.
