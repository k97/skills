---
name: macos-perf
description: >-
  Benchmark and review one macOS app's performance against Apple's own documented thresholds — hangs, main-thread responsiveness, launch, CPU, memory, energy — and report what to fix first. Measures under conditions that make the numbers mean something, uses Instruments via xctrace and the command-line tools, and optionally records a baseline to compare later runs against. Works on any running app, and uses better tooling when it finds an Xcode, SwiftPM, Tauri or Electron project. Use for "profile my app", "benchmark this app", "why is my app slow", "my app beachballs", "is my app leaking", "app launch is slow", "my app drains battery", "did this release get slower", "performance review before shipping", "Time Profiler", "Instruments from the command line", "xctrace", "signposts", "XCTest performance test". Careful about what is macOS guidance and what is iOS-only.
argument-hint: "<app-name|pid|bundle-path> [--hang|--cpu|--launch|--memory|--energy] [--baseline]"
source: https://github.com/k97/skills/tree/main/skills/macos-perf
metadata:
  version: "0.1.0"
---

# macos-perf

Measure one app, judge it against Apple's published thresholds, and report what to fix first. Everything here is macOS-applicable and sourced from Apple's documentation; where Apple's guidance is iOS-only, this skill says so instead of borrowing it, and where Apple's own material is archived or does not affirm macOS support, the reference covering it says so.

## Step 1 — establish the subject

A running app is named by name, pid, or bundle path. Detect a project in the working directory, because it decides what can be measured:

```bash
ls Package.swift *.xcodeproj *.xcworkspace 2>/dev/null      # Swift / Xcode
[ -f src-tauri/tauri.conf.json ] && echo tauri
[ -f package.json ] && grep -q '"electron"' package.json && echo electron
```

**The app is usually not one process.** Tauri, Electron, and anything with XPC helpers or a WebKit content process spread work across several, and the one doing the work is rarely the one named on the bundle. Enumerate with `pgrep -fl <app-name>` and attribute every number to a named process.

**Measure a release build**, with the accuracy settings Apple prescribes for performance work — see [references/measurement.md](references/measurement.md). If only a debug build exists, say so in the report rather than presenting its numbers as the app's.

## Step 2 — fix hangs first

Apple's stated priority, not this skill's: _"by fixing the hangs, you're likely to fix major sources of hitches as well."_ Unresponsiveness dominates how fast an app feels, and it is measured differently from throughput. Start at [references/responsiveness.md](references/responsiveness.md) unless the complaint is plainly about something else.

## Step 3 — measure

| Flag | Question | Read |
| --- | --- | --- |
| `--hang` | does the main thread block, and on what | [references/responsiveness.md](references/responsiveness.md) |
| `--cpu` | where does it spend CPU, and is that work necessary | [references/cpu.md](references/cpu.md) |
| `--launch` | how long from launch to first frame | [references/responsiveness.md](references/responsiveness.md) — Launch |
| `--memory` | footprint, growth, leaked vs abandoned | [references/memory.md](references/memory.md) |
| `--energy` | wakeups, QoS, sleep assertions, thermal behaviour | [references/energy.md](references/energy.md) |

[references/instruments.md](references/instruments.md) carries the `xctrace` mechanics and template selection every branch uses. No flag: hangs, then CPU, then memory, then energy, stopping early if one plainly explains the complaint.

## Step 4 — review

[references/review.md](references/review.md) has the report shape and the baseline format. `--baseline` writes one; when a baseline exists, compare and lead with what moved.

## Apple's thresholds

These are the verdicts, and this table is where they live — the references apply them rather than restating them. They are Apple's published numbers, and they are what turns a measurement into a finding:

| Measure | Apple's threshold | Source |
| --- | --- | --- |
| Discrete interaction (a click) | < 100 ms feels instant; assume less than half is yours | Improving app responsiveness |
| Main-thread work, continuous interaction | < 5 ms | Improving app responsiveness |
| One display refresh | 16.7 ms at 60 Hz, 8.3 ms at 120 Hz | Understanding hitches in your app |
| Main run loop unresponsive | 250 ms — tools start reporting here | Understanding hangs in your app |
| 250–500 ms | "micro hang" | WWDC23 session 10248 |
| > 500 ms | "proper hang" | WWDC23 session 10248 |
| Idle wakeups | more than one per second when idle indicates a problem | Energy Efficiency Guide for Mac Apps |
| CPU at 1% / 10% / 100% | 1.1× / 2× / 10× idle power draw | Energy Efficiency Guide for Mac Apps |
| Time at or below utility QoS when the user is idle | at least 90% | Energy Efficiency Guide for Mac Apps |

## Invariants

- **A number without its conditions is not a measurement.** Machine, OS version, build configuration, thermal state, and power source travel with every figure. Numbers taken on battery, or on a machine that was already hot, do not compare with numbers taken plugged in and cool.
- **One run is an anecdote.** Several runs, discard the first, report the median and the spread — the same shape as Apple's own `measure` API. A 5% improvement inside 15% run-to-run variance is nothing.
- **Sampling has a bias, and Apple names it.** Time Profiler samples on a timer and over-represents periodic work, so Apple's current guidance is to prefer CPU Profiler for CPU optimisation.
- **A leak and abandoned memory are different bugs**, and `leaks` finds only one of them.
- **macOS has no jetsam**, no per-process memory limit and no low-memory warning — a large footprint costs the whole machine rather than killing the app, so no iOS memory threshold transfers.
- **CPU percentages are per-core**, so 400% on an 8-core machine is four cores busy.
- **`top`'s first sample is computed from a delta it does not have yet**, so `-l 1` reports a figure describing nothing — take two, read the second. `ps` `%cpu` is a decaying average over up to a minute and smears short spikes.
- **Three things look like "permission denied", and only one is fixed by `sudo`.** Inspecting a process you do not own (`sample`, `footprint`, `leaks`, `heap`, `vmmap`) needs root. An Apple-signed or SIP-protected binary refuses regardless. Your own hardened, notarised build refuses until rebuilt with `get-task-allow` — a debug build.
- **The `instruments` CLI is gone.** Apple deprecated it in Xcode 12 in favour of `xctrace` and it is absent from current Xcode; reports of `xcrun: error: unable to find utility "instruments"` start appearing around Xcode 13. `xcrun xctrace` replaces it and needs full Xcode rather than the Command Line Tools.

## Reading Apple's documentation

Apple's documentation pages are JavaScript-rendered and return an empty shell to a plain fetch. **Appending `.md` to any `developer.apple.com/documentation/...` URL returns the article source**, including a machine-readable `availability` block giving exact per-platform version requirements. Use it to check a claim before repeating it — particularly to check whether an API or metric exists on macOS at all, since much of Apple's performance material is written for iOS.

## Scope

Measurement and review, not remediation: this skill produces numbers, judges them against the thresholds above, and ranks what to fix. It does not rewrite the app or tune the machine to flatter a benchmark. When the finding is that something else on the system is the problem, say so and name it rather than continuing to profile the app.
