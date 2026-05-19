# Page spec: Login / Register (`auth`)

## Purpose
Gate every other page behind a Firebase email/password login. Block users
whose `users/{uid}.status` is `pending` or `rejected`.

## Files
| Tab id | Template | Module(s) |
|---|---|---|
| *(none — pre-app)* | `www/templates/auth.html` | `www/js/modules/authentication.js` |

## Who can use it
Anyone with internet access.

## What the user sees (top → bottom)
1. Login form (`#loginForm`): email + password + Login button.
2. Toggle to Register form (`#signupForm`): email + password + display
   name + Register button.
3. "Forgot password?" link → sends Firebase password reset email.

## What the user can do
| Action | Effect | Writes to |
|---|---|---|
| Login | `firebase.auth().signInWithEmailAndPassword()` → load app shell | — |
| Register | `firebase.auth().createUserWithEmailAndPassword()` → create `users/{uid}` doc with `status: 'pending'`, `role: 'staff'` | `users/{uid}` |
| Reset password | Sends Firebase reset email | — |

## Calculations / formulas
None on this page. Pure auth flow.

## Data sources
- Firebase Auth state.
- `users/{uid}` document for status and role.

## Must NOT do
- Must not let `pending` or `rejected` users reach any other tab.
- Must not write to `users/` with anything except
  `{ status: 'pending', role: 'staff', displayName, createdAt }` on
  register. Role promotion is admin-only.
- Must not surface raw Firebase error codes — user-facing message only
  ("invalid email", "wrong password", etc.).

## Known issues
None currently tracked.

## Example bug reports → what to change
- "After I register I'm immediately taken into the app" → registration
  must set `status:'pending'` and the post-register screen must say
  *"Awaiting approval"*. Check `authentication.js` register flow.
- "I can see the Admin tab as a staff" → `users/{uid}.role` not being
  read on login. Check the role-gating block in `main.js`.
