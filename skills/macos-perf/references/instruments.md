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

## Choosing a sampler

Apple's current guidance (WWDC25 session 308) inverts the habit of reaching for Time Profiler:

> "You should prefer CPU Profiler over Time Profiler for CPU optimization because it's more accurate and more fairly weights software consuming CPU resources."

Time Profiler samples on a timer and **suffers from aliasing bias**: periodic work lands on the sampling beat and is over-represented, and CPUs running at higher clock speeds are under-weighted. CPU Profiler samples each CPU based on its own clock frequency, which on Apple Silicon — where cores run at very different frequencies — matters a great deal.

Use **Deferred Mode** when Instruments is running on the same machine as the thing being profiled, which on macOS is always. It keeps the recorder's own overhead out of your measurement.

The ladder, in order:

1. **CPU Profiler** — where is the CPU going, by call tree.
2. **Processor Trace** — what abstraction costs (generics, protocol dispatch, ARC, bounds checks). No sampling bias at all: Apple says the device is "typically less than 1% slower". Requires **M4 or later and macOS 15.4+** to record, though any Mac can analyse a recorded trace. It produces gigabytes per second, so wrap the region in a signpost and keep it to seconds. Enable under Privacy & Security > Developer Tools.
3. **CPU Counters** — branch prediction and cache behaviour, once the call tree is no longer the answer.

Other templates Apple names for app performance: **Allocations** and **Leaks** (memory), **File Activity** (I/O), **System Trace** (thread states and system calls), **Swift Concurrency**, and the **os_signposts** / Points of Interest instrument, which you can add to a Blank template.

## Templates worth checking rather than assuming

Apple publishes no platform-annotated list of Instruments templates. **App Launch**, **Animation Hitches** and **Energy Log** are all documented in iOS-device terms, and whether each can target a macOS app is not stated either way. The authoritative check takes five seconds: open Instruments with the macOS target selected, and the chooser greys out what it cannot profile. Check before promising one.

Older material still references a **Core Animation** template; Apple's current documentation points to Animation Hitches instead, so treat Core Animation as superseded unless you see it in the chooser.
