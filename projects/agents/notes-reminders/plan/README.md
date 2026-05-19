# Plan — notes-reminders

## Status

**Early-stage idea capture.** No code, no chosen tenant, no chosen
capture surface.

## Next steps

1. **Audit existing tools.** Copilot for M365, AudioPen, Otter,
   Microsoft Loop. Confirm the capture-and-auto-route shape is the
   actual gap.
2. **Pick the tenant** (work vs personal).
3. **Pick the capture surface** (desktop hotkey, mobile, both).
4. **Walking skeleton**: push-to-talk on desktop, Whisper local, save
   raw transcript to local SQLite. No classification yet. Hotkey to
   search.
5. **Add classifier** — start with two classes (note vs todo) and
   expand once accuracy is solid.
6. **Add one output adapter** (probably Microsoft To Do for todos).
7. **Add morning brief** — pending reminders + yesterday's captures.
8. **Add FTS5 search** with natural-language rewrite.

## Risks

- **Capture latency** kills the habit. Test on a slow machine.
- **STT accuracy on quiet mics** — Whisper tiny is bad; balance vs
  speed.
- **Auto-route mistakes** are demoralizing. Generous "unrouted"
  bucket + low friction to re-classify.
- **Existing tools may already do this** — audit before building.

## Known issues

(none yet — no code)
