# Hangs, the main thread, and launch

Apple's priority, stated plainly: **"Fix hangs first."** Unresponsiveness dominates how fast an app feels, and fixing it usually fixes rendering stutter as a side effect.

## What counts as a hang

Apple's definition covers macOS explicitly — the spinning wait cursor is named as the macOS form of the symptom. Detection measures the **busy portion of the main run loop**: the duration between two "waiting for events" periods. That is a proxy, so Apple calls what the tools report **potential hangs** — the condition is detected whether or not a user happened to be interacting at the time.

Judge durations against the thresholds table in SKILL.md. Two things that table cannot carry: Apple calls a stall between 100 and 250 ms one you "might get away with", and Instruments labels multi-second stalls a **Severe Hang** without publishing the cutoff at which it switches — so report the duration and let the reader place it, rather than claiming a Severe Hang boundary.

When budgeting rather than judging, Apple adds that you should "assume that less than half" of the 100 ms discrete-interaction budget is available to your app's main thread.

## Busy or blocked — the triage split

This decides the tool, and getting it backwards wastes the session:

- **Busy** — CPU activity on the main thread. It is doing too much work. → Time Profiler / CPU Profiler, and move the work off the main thread.
- **Blocked** — little or no CPU on the main thread. It is waiting: a lock, a semaphore, synchronous I/O, a synchronous XPC or network call. → **Thread State Trace**, which shows what it is waiting on. A CPU profiler shows almost nothing here, which is itself the diagnosis.

## Tools

**Thread Performance Checker** is the cheapest win and Apple states it is "currently supported only on macOS and iOS". It detects **priority inversions** and **non-UI work on the main thread** with no recompilation, and is on by default for the Run action. Turn findings into test failures via Product > Test Plan > Edit Test Plan > Configurations > Runtime API Checking > **On (as Failure)**. Suppress known-noisy frames with a `PERFC_SUPPRESSION_FILE` listing `class:` and `method:` lines.

**The Hangs instrument** is included in the Time Profiler, CPU Profiler and Hitches templates. It needs Instruments 14 and **macOS 13 or later**, and lets you lower the reporting threshold below 250 ms.

**`spindump`** captures system-wide stacks, so unlike `sample` it also captures the thread holding the lock your main thread is waiting on:

```bash
sudo spindump <pid> 10 -o /tmp/spin.txt
```

macOS also writes `.spin` reports automatically, visible in Console.app under Spin Reports. Note that `spindump` is practitioner territory — `man spindump` is the reference; Apple's current developer documentation routes hang diagnosis through Instruments and the Thread Performance Checker, not through it.

## Frame budget

A delay as small as a single refresh interval — the frame budget in SKILL.md's table — causes a visible hitch, well below the 50–100 ms at which a delay starts reading as a hang. Hitches and hangs are therefore different scales of the same problem, and Apple's ordering holds: the hang is the one to fix.

> iOS-only, do not apply to macOS: the Xcode Organizer **hitch-rate** metric and its 10 / 25 / 50 ms-per-second scale are explicitly iOS and iPadOS only. Quoting that scale as a macOS target is wrong.

## Launch

Apple measures launch as **time to first frame**, "including the time required to draw the views that are displayed on that first frame". Work done after the first frame does not count — instrument that separately with `.pointsOfInterest` signposts.

> The widely quoted **400 ms launch target is iOS-only**. It comes from WWDC19 session 423 and is justified entirely by the duration of the iOS launch animation; the session never mentions macOS, and the figure appears in no current Apple documentation. macOS indicates launch with a bouncing Dock icon of indefinite duration. Do not present 400 ms as an Apple target for a Mac app.

Two things Apple does say about macOS launch specifically: the system "will not terminate your process as part of normal use" — there is no watchdog, and none of the `0x8badf00d` watchdog-termination material applies — and an activation "may require the system to bring in memory from the compressor, swap, and re-render", which is the macOS analogue of a cold launch and is worth measuring after the app has sat idle rather than only after a fresh build.

The **dyld Activity** instrument measures time in static initialisers, which is the usual pre-main cost. Apple's App Launch template is documented in iOS terms; [instruments.md](instruments.md) covers how to check whether a template can target a macOS app.

## Field data

**MetricKit is available on macOS 12 and later** — not iOS-only, despite its reputation — and delivers reports at most once per day. It provides hang time, launch and memory metrics, plus custom signpost intervals. Framework-level availability does not guarantee every individual metric on macOS, so check a specific symbol's availability block before relying on it.

Xcode Organizer reports **hang rate** for macOS ("seconds per hour that the app is unresponsive", counting only periods over 250 ms, shown as median and 90th percentile). It does **not** provide hang reports with stack traces for macOS — those are iOS and iPadOS only.
