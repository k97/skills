# CPU

Where the app's CPU time goes, and whether that work needs doing at all. [instruments.md](instruments.md) covers which sampler to use and how to drive it; this is what to do with the result.

## A first look without Xcode

```bash
top -pid <pid> -l 2 -stats pid,command,cpu,mem,th | tail -5
sample <pid> 10 -file /tmp/sample.txt
```

`sample` attaches, collects call stacks for N seconds and prints a tree sorted by where time went. No Xcode, no root for a process you own, and it answers the question often enough to skip Instruments entirely. Note it takes `-file`, while `spindump` takes `-o`.

Read the heaviest **leaf** frames — the callers stacked above them are context, not cost. Two readings matter more than the function names:

- Stacks in application code → genuine compute. Profile properly and optimise, or move it off the main thread.
- Stacks in `mach_msg_trap`, `select`, `read`, `semaphore_wait` → **waiting**, not computing. The bottleneck is disk, network, a lock, or another process, and no amount of CPU optimisation will touch it. If the waiting thread is the main thread, this is a hang — go to [responsiveness.md](responsiveness.md).

## Attribute the work before optimising it

The useful question is rarely "which function is hottest" but "why is this running at all". Per-launch initialisation that could be lazy, work repeated per frame that could be cached, a timer firing far more often than the UI changes, and a polling loop standing in for a notification all show up as a plausible-looking hot function that should not be executing.

Apple's Quality of Service classes are the lever for work that genuinely must happen, and misassigned QoS is simultaneously a responsiveness bug and an energy bug. [energy.md](energy.md) has the class-to-work mapping.

## Apple Silicon core clusters

Work placed on the efficiency cluster runs slower by design, which reads as "slow" with no contention anywhere:

```bash
sysctl -n hw.perflevel0.logicalcpu     # performance cores (macOS 12+, Apple Silicon only)
sysctl -n hw.perflevel1.logicalcpu     # efficiency cores
```

Low-priority QoS classes are placed there deliberately. A background task running slowly on the E-cluster is usually correct behaviour; the bug is when work the user is waiting on has been given a QoS that lands it there.

`sudo powermetrics --samplers cpu_power -i 1000 -n 5` shows per-cluster residency and frequency, which is how you tell "not running" from "running slowly on the small cores".

## Multi-process apps

For Tauri, Electron, and anything with helpers, profile the process doing the work rather than the one named on the bundle:

```bash
pgrep -fl MyApp
```

A web-based UI layer splits the question in two: the native side profiles with the tools here, while the renderer needs the web inspector's own profiler. Report them separately — a combined figure hides which half to fix.

## Comparing before and after

Apple's own loop: gather data, pick the metric, profile, **change one thing**, compare. Keep the _before_ trace and produce an _after_ trace under the same conditions, then, in Apple's words, "consider writing a performance test in XCTest to protect against future regressions". [measurement.md](measurement.md) has the conditions that make the comparison valid, and [review.md](review.md) the format for recording it.
