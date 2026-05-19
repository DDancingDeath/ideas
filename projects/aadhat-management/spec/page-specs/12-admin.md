# Page spec: Admin (`admin`) — owner-only

## Purpose
The owner's control room: approve new staff, change roles, edit
business config, run dangerous data tools.

## Files
| Tab id | Template | Module(s) |
|---|---|---|
| `admin` | `www/templates/admin.html` (+ `users.html`, `configure.html`) | `www/js/modules/admin.js`, `users.js` |

## Who can use it
**Owner + Admin only.** Nav link is hidden for staff. Even if a staff
manages to navigate via URL hash, every action must re-check the role
server-side via `firestore.rules`.

## What the user sees
Three subtabs:
1. **Configure**: business name, address, phone, GSTIN, default labor
   rate, default heavy-weight, etc.
2. **Users**: list of all users; per-user approve / reject / change
   role / delete.
3. **Data**: export, reseed (test data), wipe (dangerous).

## What the user can do
| Action | Effect | Writes to |
|---|---|---|
| Approve user | sets `users/{uid}.status = 'active'` | `users/{uid}` |
| Reject user | sets status to `rejected` | `users/{uid}` |
| Change role | sets `users/{uid}.role` | `users/{uid}` |
| Delete user | removes Firestore doc + Auth account (Cloud Function `admin-deleteAuthUser`) | `users/{uid}` + Auth |
| Save business config | persists to `localStorage` and `businessConfig/main` | `businessConfig/main` |
| Wipe data | deletes all collections (asks for typed confirmation) | many |

## Calculations / formulas
None — this is a control panel, not a calculator. The only derived
display is the user count by role:
```
ownerCount = users.filter(u => u.role === 'owner').length
adminCount = users.filter(u => u.role === 'admin').length
staffCount = users.filter(u => u.role === 'staff').length
pendingCount = users.filter(u => u.status === 'pending').length
```

## Must NOT do
- Must not let an admin demote the **last** owner. (Lockout protection:
  block the role change if `ownerCount === 1` and the target is the
  current owner.)
- Must not delete a user without also deleting their Auth account.
  Orphan Auth accounts can re-register with the same email and
  unexpectedly inherit the role doc by uid collision.
- Wipe-data must require typing **`WIPE`** (or the localized equivalent)
  exactly — not just clicking a yes button.
- Must not allow a staff user to even render the Admin nav link.

## Known issues
- See REVIEW_ISSUES Section F.

## Example bug reports → what to change
- "I changed a user's role but the Admin tab they're on still works"
  → role check is read once at login; need to re-read on tab switch
  or push role changes via a Firestore listener and force re-render.
- "Delete user crashed with permission denied" → the
  `admin-deleteAuthUser` Cloud Function isn't deployed in this env,
  or its caller-role check rejected the call. Check the Functions
  logs.
