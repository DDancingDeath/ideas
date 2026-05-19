# Page spec: Settings (`settings`)

## Purpose
Per-user UI preferences and Bluetooth printer pairing.

## Files
| Tab id | Template | Module(s) |
|---|---|---|
| `settings` | `www/templates/settings.html` | `www/js/modules/settings.js` |

## Who can use it
Any authenticated user. Settings are per-device (`localStorage`), not
per-user-account.

## What the user sees
1. **Dark mode** toggle.
2. **Show Hindi** toggle (renders Hindi name alongside English in lists).
3. **Bluetooth printer**: scan / connect / disconnect / test print
   (Cordova plugin — Android only).
4. **Logout** button.

## What the user can do
| Action | Effect | Writes to |
|---|---|---|
| Toggle dark / Hindi | Updates `AppState.settings`, persists to `localStorage` key `settings` | — (no Firestore) |
| Connect printer | Pairs via Cordova `BluetoothSerial` plugin | local plugin state |
| Test print | Sends ESC/POS test page | — |
| Logout | `firebase.auth().signOut()` + clears AppState | — |

## Calculations / formulas
None.

## Data sources
- `localStorage.getItem('settings')` (JSON-encoded).
- `BluetoothSerial.list()` for paired devices.

## Must NOT do
- Must not store anything sensitive in `localStorage` (no tokens, no
  passwords).
- Bluetooth print code must not crash on web/desktop where the Cordova
  plugin isn't loaded — feature-detect (`window.bluetoothSerial`)
  before calling.
- Must not corrupt the printer config on a failed connect — write only
  after a successful pair.

## Known issues
- See REVIEW_ISSUES Section C / settings entries.

## Example bug reports → what to change
- "Dark mode resets when I refresh" → settings save fires but read
  doesn't run before render; ensure `loadSettings()` runs before the
  first `applyTheme()` call.
- "Hindi name doesn't appear in items list after toggling" → the
  toggle handler updates `AppState.settings.showHindi` but doesn't
  re-render the items list. Force a re-render after toggle.
- "Print just hangs" → Bluetooth pairing succeeded but ESC/POS write
  is failing silently. Check `BluetoothSerial.write()` callback for
  an error.
