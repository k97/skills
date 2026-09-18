# Instruments and xctrace

The mechanics every branch shares. `xcrun xctrace` needs full Xcode, not the Command Line Tools — `xcode-select -p` must print a path inside `Xcode.app`.

## Apple's documentation for xctrace is the man page

There is no web reference page. Apple's Xcode command-line tool reference points at `man xctrace`, and flags change between Xcode versions, so check the local man page rather than trusting any written example — including this one.

## Recording

```bash
xcrun xctrace list templates                     # what this Xcode ships
xcrun xctrace list instruments

xcrun xctrace record --template 'Time Profiler' \
  --attach <pid|name> --time-limit 30s --output /tmp/app.trace

xcrun xctrace record --template 'Time Profiler' \
  --output /tmp/app.trace --launch -- /Applications/MyApp.app/Contents/MacOS/MyApp
```

The `--` before the launch target is required. `--all-processes` records everything on the machine, which is occasionally what you want for a system-wide question and almost never what you want when profiling one app. Time limits take a unit suffix: `ms`, `s`, `m`, `h`. Device flags are irrelevant when profiling the Mac you are sitting at.

## Exporting without the GUI

Two steps, because the schema names differ per trace. Dump the table of contents first, then XPath into what it reveals:

```bash
xcrun xctrace export --input /tmp/app.trace --toc

xcrun xctrace export --input /tmp/app.trace \
  --xpath '/trace-toc/run[@number="1"]/processes'
```

Output is XML. `xctrace symbolicate --input /tmp/app.trace --dsym MyApp.dSYM` fills in missing symbols.

Two tables worth knowing by name. Time Profiler and CPU Profiler traces carry `potential-hangs` — the `--hang` branch's worst-main-thread-block figure:

```bash
xcrun xctrace export --input /tmp/app.trace \
  --xpath '/trace-toc/run[@number="1"]/data/table[@schema="potential-hangs"]'
```

System Trace traces carry `thread-state`, which is the blocked-main-thread evidence [responsiveness.md](responsiveness.md) asks for.

## Choosing a sampler

Apple's current guidance (WWDC25 session 308) inverts the habit of reaching for Time Profiler:

> "You should prefer CPU Profiler over Time Profiler for CPU optimization because it's more accurate and more fairly weights software consuming CPU resources."

Time Profiler samples on a timer and **suffers from aliasing bias**: periodic work lands on the sampling beat and is over-represented, and CPUs running at higher clock speeds are under-weighted. CPU Profiler samples each CPU based on its own clock frequency, which on Apple Silicon — where cores run at very different frequencies — matters a great deal.

Use **Deferred Mode** when Instruments is running on the same machine as the thing being profiled, which on macOS is always. It keeps the recorder's own overhead out of your measurement.

The ladder, in order:

1. **CPU Profiler** — where is the CPU going, by call tree.
2. **Processor Trace** — what abstraction costs (generics, protocol dispatch, ARC, bounds checks). No sampling bias at all: Apple says the device is "typically less than 1% slower". Requires **M4 or later and macOS 15.4+** to record, though any Mac can analyse a recorded trace. It produces gigabytes per second, so wrap the region in a signpost and keep it to seconds. Enable under Privacy & Security > Developer Tools.
3. **CPU Counters** — branch prediction and cache behaviour, once the call tree is no longer the answer.

Other templates for app performance: **Allocations**, **Leaks** and **File Activity**, named in Apple's "Improving your app's performance"; **System Trace** (thread states and system calls) and **Swift Concurrency**, which Apple documents only in Xcode release notes; and the **os_signpost** / Points of Interest instrument, which you can add to a Blank template.

## Templates on a macOS target — checked, not assumed

Apple publishes no platform-annotated list of Instruments templates, so this was settled by recording a Mac app with each (Xcode 27, macOS 26):

- **App Launch** and **Animation Hitches** both record a macOS target, and Animation Hitches carries the Hangs instrument. App Launch's launch-lifecycle table came back empty on macOS — [responsiveness.md](responsiveness.md), Launch — and Apple's Xcode 12 release notes record hitch intervals not showing for macOS apps before the Xcode 26 redesign, so check the trace has rows before quoting it.
- **Energy Log** no longer exists — Apple removed it in Xcode 13 (release note 74161279) — and its successor **Power Profiler** refuses a Mac outright: _"The Power Profiler instrument is not supported on macOS. Record on iOS or iPadOS instead."_ Energy on macOS is `powermetrics` and Activity Monitor: [energy.md](energy.md).

A different Xcode may differ. `xcrun xctrace list templates` is the five-second check for what ships, and a template that lists but cannot profile the target says so on the first line of `xctrace record`'s output.
