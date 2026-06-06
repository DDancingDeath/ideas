# Orchestration runbook

The runbook for running the parallel build described in `./README.md`. The
orchestrator can be a human, a single Copilot CLI session driving subagents, or
any mix. Worker agents are stateless — every invocation gets the full prompt.

## Roles

- **Orchestrator** — owns the contract, the meta-repo skeleton, integration,
  and the final demo. Sequential work, ~3 h total across M0 + M-integration +
  M-final.
- **Worker × 3** — each owns one component (backend, device agent, phone).
  Stateless; reads its prompt + the contract; produces a PR.

## Two execution modes

### Mode A — Three terminals, three Copilot CLI sessions

Best for the first run. Real-time visibility into each worker.

```powershell
# Terminal 1 — backend worker
cd C:\repos\remote-app-launcher
git checkout track/backend
copilot --autopilot --prompt "$(Get-Content D:\ideas\projects\apps\remote-app-launcher\prompts\track-backend.md -Raw)"

# Terminal 2 — device-agent worker
cd C:\repos\remote-app-launcher
git checkout track/agent
copilot --autopilot --prompt "$(Get-Content D:\ideas\projects\apps\remote-app-launcher\prompts\track-agent.md -Raw)"

# Terminal 3 — phone worker
cd C:\repos\remote-app-launcher
git checkout track/phone
copilot --autopilot --prompt "$(Get-Content D:\ideas\projects\apps\remote-app-launcher\prompts\track-phone.md -Raw)"
```

You monitor each terminal independently. When all three call `task_complete`
and open PRs, you proceed to M-integration.

### Mode B — Single Copilot CLI session, three `task` subagents

Lower-friction once you trust the workers. One context window owns the
orchestration; three background agents do the work.

In the orchestrator's session:

```
task agent_type=general-purpose name=backend mode=background \
  prompt="<entire contents of prompts/track-backend.md>"

task agent_type=general-purpose name=agent mode=background \
  prompt="<entire contents of prompts/track-agent.md>"

task agent_type=general-purpose name=phone mode=background \
  prompt="<entire contents of prompts/track-phone.md>"
```

Each subagent runs in its own context window. The orchestrator polls them
with `read_agent` and proceeds to M-integration when all three signal done.

Note: in Mode B all three subagents are operating on the same checkout
unless each is told to `git worktree add` its own working copy. Recommended
first line in each track prompt for Mode B:

```
git worktree add ../wt-<track> track/<track>
cd ../wt-<track>
```

## Worker contract

Every worker MUST:

1. Read only the files listed in its prompt's "Context loading" section.
2. Stay inside its assigned folder (`pa-backend/`, `pa-agent/`, `pa-phone/`)
   plus an adjacent test folder.
3. NOT edit `docs/contracts.md` or any other track's folder.
4. NOT touch the root `README.md` or the root `.gitignore` (orchestrator owns
   those).
5. Pass its **local acceptance gate** (defined in the prompt) using mocks for
   the other two components.
6. Open a PR with acceptance evidence (test output + transcript / screenshot)
   in the description.
7. STOP if it discovers a contract bug. Do not invent a workaround. Post a
   `CONTRACT_CHANGE` note.

## Contract-change protocol

The contract is frozen at the end of M0. If a worker hits a real contradiction
(missing field, ambiguous status, type collision), follow this protocol —
unilateral contract edits break the parallel guarantee.

1. **Worker stops** at the point of contradiction (no rollback, no workaround).
2. Worker emits a `CONTRACT_CHANGE` note:
   - What's wrong (specific file + section).
   - What they propose (concrete diff against `docs/contracts.md`).
   - What's blocked (which acceptance test fails without the fix).
3. **Orchestrator inspects and decides yes/no** (≤ 5 min).
4. If yes: orchestrator updates `docs/contracts.md` on `main`, force-fetches
   it into each track branch (`git checkout track/X && git checkout main -- docs/contracts.md`),
   commits. Also updates `spec/contracts.md` in the ideas repo (the canon).
5. Worker(s) rebase off updated `main`. Acceptance evidence is re-run.
6. Orchestrator appends the decision to the decision log in `./README.md`.

Workers never edit `docs/contracts.md` themselves.

## Per-track handoff artifacts

| Track | PR branch → target | Required in PR description |
| --- | --- | --- |
| Backend | `track/backend` → `main` | `dotnet test` output (all green); curl transcript covering POST → long-poll-GET → POST-result → GET-status. |
| Agent   | `track/agent`   → `main` | `dotnet test` output (all green); `dotnet run` log against `pa-agent.dev-mock/` PowerShell stub showing notepad launch + result POST. |
| Phone   | `track/phone`   → `main` | `npm test` output (all green); screenshot of Expo Go showing the screen with `EXPO_PUBLIC_PA_BACKEND_URL` placeholder. |

If any of these are missing, the orchestrator sends the PR back with a
targeted follow-up prompt naming the missing artifact.

## Failure handling

| Symptom | Orchestrator action |
| --- | --- |
| One track fails local acceptance | Send a targeted follow-up prompt to that worker. Others keep running. |
| All three tracks fail | Likely contract bug. Re-read `spec/contracts.md` end-to-end, fix the contract, re-spawn workers. |
| Backend track wall-clock > 3 h | Kill, do it yourself. It's the smallest component. |
| Phone track wall-clock > 4 h | Phone is the largest. If still progressing, let it run. If stuck, ask the agent for a partial commit + a diagnostic note explaining where it's blocked. |
| Two PRs conflict | Should be impossible by construction — each track owns one folder. If conflict happens, one worker violated rule #2 (stay in your folder). Revert their out-of-folder edits and re-run their acceptance. |
| Contract drift detected at M-integration | The `docs/contracts.md` in the build repo doesn't match `spec/contracts.md` in the ideas repo. Force the ideas repo to win, re-run M-integration smoke test. |

## What the orchestrator does NOT do during the parallel phase

- Inspect each worker's diffs as they happen (premature; trust the acceptance gate).
- Run other-track code from inside a worker session (workers own their gates).
- Modify the contract on a hunch (only on a documented `CONTRACT_CHANGE`).
- Merge any PR before all three are open and their gates green.

## Completion signal

The parallel phase is done when:

- All three PRs are open.
- Each PR description has its required artifacts (`dotnet test` / `npm test` output + transcript / screenshot).
- No `CONTRACT_CHANGE` notes are outstanding.

Then proceed to **M-integration** in `./README.md`.
