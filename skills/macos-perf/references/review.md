# The review, and the baseline

## Report structure

Use this shape. The conditions come first because every number below them is meaningless without them, and the findings are ranked by user-visible impact rather than by how interesting they were to find.

```markdown
# Performance review — <app> <version>

## Conditions

Machine, OS, build configuration, power source, thermal state at start and end, repetitions per measurement, and anything that could not be measured.

## Summary

Two or three sentences: what dominates, and what to fix first.

## Measurements

| Measure                 | Result | Apple's threshold          | Verdict  |
| ----------------------- | ------ | -------------------------- | -------- |
| Worst main-thread block | 780 ms | > 500 ms is a proper hang  | fail     |
| Launch to first frame   | 310 ms | no macOS target published  | recorded |
| Footprint, steady state | 240 MB | no macOS limit             | recorded |
| Idle wakeups            | 4 /s   | > 1 /s indicates a problem | fail     |

## Findings

Ranked by impact. For each: what was measured, what it means, the evidence (trace, stack, command), and the smallest change that would move it.

## Not measured

What was skipped and why — a tool that needed root you did not have, a template unavailable for a macOS target, a metric that is iOS-only.
```

Two rules for the Verdict column. Where Apple publishes a threshold, judge against it and say so. Where Apple publishes none — launch time and memory footprint on macOS both qualify — record the number and compare it against the app's own history instead of inventing a target. A fabricated threshold is worse than an honest "recorded".

Separate measurement from inference throughout. "The main thread blocked for 780 ms in `loadIndex`" is a measurement; "the index should be loaded lazily" is a recommendation, and the reader is entitled to see which is which.

## Checking an Apple claim before it goes in the report

Apple's documentation pages are JavaScript-rendered and return an empty shell to a plain fetch. **Appending `.md` to a `developer.apple.com/documentation/...` URL returns the article source**, including a machine-readable `availability` block giving exact per-platform version requirements — use it to check whether an API or metric exists on macOS at all before quoting it. Symbol paths vary; when a guess returns 404, fetch the parent page's `.md` and follow its links. Apple's archived library (`developer.apple.com/library/archive/...`) is plain HTML and fetches directly.

## Baseline format

Plain JSON beside the project, committed, so a diff is reviewable and CI can read it. [measurement.md](measurement.md) explains why this exists rather than Xcode's own baseline mechanism.

```json
{
  "app": "MyApp",
  "version": "1.4.2",
  "recorded": "2026-09-17T14:05:00+10:00",
  "conditions": {
    "machine": "MacBookPro18,3 (M1 Pro)",
    "os": "26.1",
    "build": "Release",
    "power": "AC",
    "thermal_start": "nominal",
    "thermal_end": "nominal",
    "iterations": 10
  },
  "measurements": {
    "launch_to_first_frame_ms": { "median": 310, "spread": 24 },
    "worst_main_thread_block_ms": { "median": 780, "spread": 110 },
    "footprint_steady_mb": { "median": 240, "spread": 6 },
    "idle_wakeups_per_s": { "median": 4, "spread": 1 }
  }
}
```

Every measurement carries a spread, because that is what decides whether a later difference is real.

## Comparing against a baseline

Lead the report with what moved, then the full table.

A change counts as a regression when it exceeds the combined spread of the two runs, not when the median moved. That is the same standard Apple applies to its own baselines, described in [measurement.md](measurement.md) — the spread is the threshold, not decoration.

Refuse the comparison outright when the conditions differ in a way that invalidates it: a different machine, a different build configuration, one run on battery, or a run that ended at `serious` thermal state. Say the comparison was not possible and why. A regression report built on mismatched conditions sends someone hunting a change that never happened, which costs more than having no baseline at all.
