# Performance budgets — rebuild

> The "no UI hang" promise from the owner is a product requirement
> in the rebuild, not polish. This file gives that promise
> measurable numbers, a reference device, a measurement methodology,
> and CI gates so regressions are caught automatically.

## Reference device

`TODO(spec)`: the owner should confirm. The plan's tentative
recommendation in
[`plan/rebuild/decisions.md`](../../plan/rebuild/decisions.md) is
a mid-range Android in the **₹15 000 – ₹20 000** range — for
example a Pixel 6a-class device or a current Redmi Note. This
matches what the shop staff actually uses.

Until confirmed, the budgets below are written against that
**reference profile**:

- CPU: roughly Snapdragon 695 / Tensor G1 class
- RAM: 6–8 GB
- Storage: UFS 2.2
- Network: 4G LTE with ~50 ms RTT and ~5 Mbps (worst common shop
  Wi-Fi)
- Printer: ESC/POS Bluetooth thermal printer (SPP), pairing
  established

A "lower-end" profile (e.g. Snapdragon 4-series, 4 GB RAM, 3G) is
allowed to miss some budgets by ≤ 50 %; we record but do not
block on it.

## Budgets

All numbers are wall-clock, observed on the reference device, on
the synthetic dataset described below. UI numbers are measured
from the user input event (`pointerdown`) to the first paint that
reflects the new state.

### Billing — the hottest path

| Action | Budget | Notes |
|---|---|---|
| Tap Save (online) | UI responds ≤ **100 ms** | Bill row exists in History within 500 ms |
| Tap Save (offline) | UI responds ≤ **100 ms** | Outbox row exists locally within 100 ms |
| Tap Print | Button transitions to `Printing…` ≤ **100 ms** | UI thread unblocked; no input dropped during BT send |
| Repeat tap Print (slow BT) | UI shows `Already printing…` ≤ **100 ms** | No new `print_attempt` event |
| Add line to bill | Form re-renders ≤ **50 ms** | Totals recompute synchronously in domain |
| Edit qty / rate | Totals re-render ≤ **50 ms** | Same |
| Change party / item via picker | Picker open ≤ **150 ms**, type-ahead ≤ **50 ms** per keystroke | Item picker is the single biggest UX item |
| Bill draft restore on reload | Form rehydrated ≤ **300 ms** | After app cold-start, draft must not be lost |

### Read pages

| Action | Budget |
|---|---|
| Open Today | All KPIs paint ≤ **500 ms** |
| Open History (first page) | First 20 rows paint ≤ **500 ms** |
| Scroll History 100 more rows | ≤ **150 ms** to paint next page |
| Open Stock | First 50 items paint ≤ **500 ms** |
| Open Outstanding | First 50 parties paint ≤ **500 ms** |
| Open Cash close | Current session totals ≤ **300 ms** |
| Open Reports (last month) | First chart paints ≤ **1500 ms** |
| Open Reports (last year) | First chart paints ≤ **3000 ms**, others stream in |
| Open Review Queue | First page paints ≤ **500 ms** |
| Open Audit log | First 50 rows paint ≤ **500 ms** |

### App-level

| Action | Budget |
|---|---|
| Cold start to Today | ≤ **2500 ms** |
| Warm start to Today | ≤ **800 ms** |
| Route navigation | ≤ **100 ms** transition; no input dropped |
| Long task (any) | ≤ **50 ms** during billing flows; ≤ **200 ms** elsewhere |
| Memory after 1h shop-day simulation | ≤ **300 MB** resident on the reference device |

### Print queue

| Action | Budget |
|---|---|
| `print_attempt` enqueued | ≤ **50 ms** from user tap |
| BT send (mocked driver) | ≤ **100 ms** to confirm `OK` |
| BT send (real printer, average case) | ≤ **2000 ms** to printed; UI never blocked |
| BT timeout | ≤ **5000 ms** to detect; surfaces `failed`, button becomes `Retry` |

### Sync / outbox

| Action | Budget |
|---|---|
| Outbox flush on reconnect | first item attempted ≤ **1000 ms** after `online` event |
| Outbox throughput | ≥ **10 events / second** sustained on the reference profile |
| Conflict detection (same `idempotencyKey`, different payload) | ≤ **500 ms**; raises `dedup.conflict` |

### Voice billing

| Action | Budget |
|---|---|
| Mic open after tap | ≤ **200 ms** |
| First parsed token to form field | ≤ **300 ms** after user stops speaking |
| Final commit to draft | ≤ **800 ms** after user stops speaking |

## Synthetic dataset

Perf tests run against a deterministic dataset:

- 250 items in the master
- 30 parties
- 18 months of events:
  - ~ 25 retail sales per day
  - ~ 5 wholesale sales per day on credit
  - ~ 4 purchases per week
  - ~ 1 cash session per day (open + close)
  - ~ 3 outstanding payments per week
  - ~ 5 expenses per week
  - sprinkled voids, corrections, adjustments
- Result: ~ 15 000 sale events, ~ 25 000 events total

This is published as `fixtures/perf-baseline.events.json` and
loaded by the perf harness.

## Methodology

### Frame-time sampling

Use the platform's frame APIs (`requestAnimationFrame` deltas, or
`performance.now()` around input handlers) plus the Long Tasks
API. Compute:

- p50 and p95 frame interval during the 5 seconds following each
  budgeted action
- count and total duration of long tasks (> 50 ms) in the same
  window

A budget passes if p95 frame interval ≤ 16.7 ms (60 FPS) **and**
the total of long tasks during the action's first 1 s ≤ 100 ms.

### End-to-end timing

Wrap each budgeted action in `performance.measure`:

```ts
performance.mark('save-tap');
await fireEvent.click(saveButton);
await waitFor(() => screen.getByText(/printed at/i));
performance.mark('save-done');
performance.measure('bill-save', 'save-tap', 'save-done');
```

Assertions read the mark and compare to the budget plus a 10 %
tolerance for noise.

### Long-task counting

Long tasks are observed via `PerformanceObserver({ type: 'longtask' })`.
The harness fails the test if any single long task exceeds the
threshold for that page's category.

### Memory

`performance.memory.usedJSHeapSize` (Chromium) or platform
equivalent, sampled before and after the 1 h shop-day simulation.

## CI gates

- The full perf suite runs **on every PR** against the synthetic
  dataset using the reference profile.
- A PR fails if **any** budget regresses by more than its tolerance
  (default 10 %) versus the baseline stored in
  `fixtures/perf-baseline.json`.
- Nightly: same suite plus the lower-end profile (record only,
  non-blocking).
- The reference baseline is bumped only by an explicit
  `perf:baseline` commit signed off by the reviewer.

## What is forbidden

- Disabling a perf assertion to make a change pass.
- Hiding work behind `setTimeout` to make a budget appear met
  while the user still waits.
- Doing money or stock math on the UI thread when it is large
  enough to be a long task. Move it to a worker or pre-compute it
  in the domain.
- Printing on the UI thread. The print queue is a worker by
  contract (see [`print-queue.md`](./print-queue.md)).
- Holding the BT lock during a UI animation.

## What is required when a budget is at risk

1. Profile under the synthetic dataset and identify the hot
   function.
2. If domain code: optimize the algorithm or move to a worker.
   Add a unit test that pins behaviour.
3. If UI: virtualize the list, memoize the selector, or break the
   render into idle callbacks.
4. If printing: confirm the queue is doing the work, not the UI;
   add a print-queue test.
5. Re-run perf suite; commit the new measurement; if the budget
   changed, get reviewer sign-off and bump baseline in a separate
   commit.

## Open items

- `TODO(spec)`: confirm the reference device.
- `TODO(spec)`: pick the exact long-task threshold for
  Reports / Analytics — Reports does heavy aggregation and may
  need a worker offload threshold higher than 50 ms.
- `TODO(spec)`: decide if cold-start budget is wall-clock from
  app icon tap, or from the runtime's "app started" callback. The
  former is honest; the latter is portable.
