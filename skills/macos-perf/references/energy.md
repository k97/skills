# Energy

Apple's target behaviour, and the standard to judge against: _"When users interact with your app, it should have a low energy impact. When users aren't interacting with your app, it should have zero energy impact."_

Most of Apple's macOS energy guidance lives in the **Energy Efficiency Guide for Mac Apps**, which is in Apple's archived library. It is still Apple's own material and still the only narrative documentation of App Nap, Energy Impact and macOS QoS — but it predates Apple Silicon and uses Objective-C-era spellings. Treat it as authoritative and dated.

## Where energy goes

CPU, timers, graphics, disk I/O and networking. Apple's CPU-to-power figures in SKILL.md's table are what make idle-time work concrete: a process sitting at 10% CPU doing nothing useful costs twice idle power, continuously.

The structural point is **fixed versus dynamic cost**: dynamic is the energy of the actual work, fixed is the cost of spinning a resource up and letting it settle back to idle. Sporadic small tasks pay the fixed cost repeatedly and never let the machine reach true idle. Apple's prescription is to **batch** — accept a higher upfront cost in exchange for a fast return to idle.

## Wakeups — the first thing to measure

Apple's idle-wakeup threshold is in SKILL.md's table and it is unambiguous. Activity Monitor shows the figure under Energy with View > Column > Idle Wake Ups, and `sudo timerfires -p <pid> -s` logs the routines responsible.

Timers are the usual cause. Apple's guidance is a **tolerance of 10% of the interval**, which lets the system coalesce wakeups:

```swift
timer.tolerance = 0.3                              // for a 3.0s interval
CFRunLoopTimerSetTolerance(timer, 0.2)             // for a 2.0s interval
```

A timer set to fire repeatedly is often the wrong construct entirely. Apple's preferred alternatives: `NSBackgroundActivityScheduler` for deferrable work, `URLSession` background sessions, dispatch sources for file, network and state changes, and semaphores instead of polling. Use `DISPATCH_TIME_FOREVER` rather than a short wait timeout — a short timeout is a polling loop wearing a disguise. Always invalidate repeating timers.

## NSBackgroundActivityScheduler — macOS only

Available on macOS 10.10+ and on no other platform, which makes it the right answer for a Mac app with maintenance work. Apple: it "gives the system flexibility to determine the most efficient time to execute based on energy usage, thermal conditions, and CPU use". Appropriate for automatic saves, backups, data maintenance, periodic fetches, updates — anything on intervals of ten minutes or more.

Its `tolerance` defaults to half the interval and its `qualityOfService` defaults to background, which Apple calls the recommended value for most activities. Poll `shouldDefer` mid-run and finish with `.deferred` when it goes true — the user may have unplugged the machine. **Failing to invoke the completion handler means the activity is never rescheduled.**

## Quality of service

| Class | Work | Duration |
| --- | --- | --- |
| User-interactive | main thread, UI refresh, animation | virtually instantaneous |
| User-initiated | opening documents, UI actions the user waits on | a few seconds or less |
| Utility | downloads, imports — typically with a progress bar | seconds to minutes |
| Background | indexing, syncing, backups — invisible to the user | minutes to hours |

Apple's headline rule is the QoS row of SKILL.md's table, in Apple's own words: _"Optimally, run your app at a QoS level of utility or lower at least 90% of the time when user activity is not occurring."_ Note that "or lower" includes utility itself. `powermetrics` is Apple's suggested way to check the actual distribution.

## App Nap

An app becomes a candidate when **all** of these hold: it is not the foreground app, it has not recently updated visible window content, it is not audible, it holds no IOKit power-management or `NSProcessInfo` assertions, and it is not using OpenGL. App Nap then lowers process priority, throttles timers, and throttles I/O.

Apple's own warning is the part people miss:

> "The preceding measures do not necessarily save energy. They primarily reduce a non-foreground app's impact on other apps. **Don't rely on App Nap to get your app to fully idle.**"

An app that idles cleanly does so because it was written to, not because the system napped it.

## Sleep assertions — the overnight-drain cause

`pmset -g assertions` names what is holding the machine awake, and Activity Monitor's **Preventing Sleep** column says which app. An app holding an assertion flattens a battery overnight while showing near-zero CPU in every other tool, so check this first when the complaint is drain with the lid closed.

Assertions are taken with `beginActivity(options:reason:)` and **must** be balanced with `endActivity(_:)`; `performActivity(options:reason:using:)` does both around a block. The options that keep the machine awake are `.idleSystemSleepDisabled` and `.idleDisplaySleepDisabled` — justified for media playback, a presentation, or a long export, and for the duration of that work only. Prefer `.userInitiatedAllowingIdleSystemSleep` when the work can tolerate the machine sleeping. Apple's scale for "lengthy user-initiated work" worth an assertion is "five or ten seconds, or even minutes, not milliseconds", and for very expensive discretionary work the advice is to defer it until the machine is plugged in.

## Thermal state

Cases are `nominal`, `fair`, `serious`, `critical`. Apple's expected app behaviour:

- **Nominal** — no action; schedule discretionary work properly.
- **Fair** — fans may be audible; an opportunity to start reducing CPU and saving energy.
- **Serious** — fans at maximum; the system is enacting countermeasures. Reduce CPU, GPU, I/O, frame rates, and use lower-quality visual effects.
- **Critical** — reduce to the absolute minimum needed to respond to the user; stop using peripherals such as the camera.

An app that ignores thermal state is a plausible answer to "why do the fans come on". [measurement.md](measurement.md) covers reading it, including the notification ordering gotcha.

## Measuring

```bash
sudo powermetrics --samplers tasks --show-process-energy -n 1
pmset -g assertions
pmset -g batt
```

Xcode's Energy Impact gauge and Activity Monitor's Energy pane both report an **Energy Impact** score. Apple defines it only as accounting for "CPU usage, network activity, disk I/O, and more" and never publishes the formula or weights — treat it as a relative indicator for comparing before and after on the same machine, never as a measurement to quote as a number.
