# Making the numbers mean something

Most performance "findings" die on the fact that the measurement was never valid. Settle this before taking a figure you intend to quote or store.

## Build and scheme settings Apple prescribes

From `Writing and running performance tests`, for measurement runs:

- Build with the **Release** configuration.
- Turn **off** "Debug executable".
- **Disable code coverage** in the test plan.
- **Disable runtime sanitizers** in the test plan.

Xcode also enables the **Thread Performance Checker** by default for the Run action, and Apple warns it "works by inserting checks" that can appear in call stacks. For profiling, use the **Profile** action rather than Run, launch from Instruments rather than attaching to an Xcode-launched process, or switch the diagnostic off. It is a correctness tool, not a measurement one.

## Repetition and variance

Apple's own `measure` API runs the block `iterationCount + 1` times and throws the first away, _"to reduce measurement variance associated with 'warming up' caches and other first-run behavior."_ (Apple does not publish the default `iterationCount` — do not claim a number.)

Do the same by hand: several runs, discard the first, report the **median and the spread**, never a single figure. If the spread is wider than the difference you are claiming, there is no difference.

## The thermal gate

`ProcessInfo.thermalState` is available on macOS 10.10.3 and later — it predates the iOS version. Past `fair` the system starts working against you: [energy.md](energy.md) has the cases and what Apple expects an app to do about each. For measurement the point is simpler — an elevated state means the benchmark is now measuring the enclosure.

Check before **and after** each run, because a long benchmark heats the machine it is measuring. A run that started `nominal` and ended `serious` is not comparable with one that stayed cool; record the state alongside the number and re-run cool.

> API gotcha, from Apple's own reference: to receive `thermalStateDidChangeNotification` you must access `thermalState` **before** registering for the notification. Code that registers first silently never fires.

Also record the power source. `pmset -g batt` says whether the machine is on AC; macOS behaves differently on battery, and Low Power Mode exists on macOS 12+ (`ProcessInfo.isLowPowerModeEnabled`, notification `NSProcessInfoPowerStateDidChange`). Apple documents the API for macOS but describes its _effects_ only for iOS — report whether it was on, do not assert what it did.

## Measuring in code — XCTest

Apple ships seven metrics: `XCTClockMetric` (wall time), `XCTCPUMetric` (CPU time, cycles, instructions retired), `XCTMemoryMetric` (physical memory delta), `XCTStorageMetric` (logical bytes written), `XCTOSSignpostMetric` (time inside a signposted region), `XCTApplicationLaunchMetric` (time to first frame of a launch; `init()` or `init(waitUntilResponsive:)`, the latter macOS 11+) and `XCTHitchMetric` (needs an `XCUIApplication`; macOS 26+). The last two measure a launched app, so they need a UI test target — a poor fit for benchmarking code, but the XCTest route to a launch figure on macOS.

```swift
func testParsePerformance() {
    let options = XCTMeasureOptions()
    options.iterationCount = 10
    measure(metrics: [XCTClockMetric(), XCTCPUMetric(), XCTMemoryMetric()],
            options: options) {
        _ = parse(fixture)
    }
}
```

Prefer the `init()` overloads. The `init(application:)` overloads require a UI test target.

`XCTOSSignpostMetric` records nothing at all when begin and end events are not matched — Apple states this explicitly, and it is the usual reason a signpost metric reports zero.

> Availability caveat, resolved: Apple's published `availability` metadata for six of the seven metric classes and for `measure(metrics:options:block:)` omits macOS while listing every other platform. That mirrors the SDK — `XCTestDefines.h` defines `XCT_METRIC_API_AVAILABLE` as `API_AVAILABLE(ios(13.0), tvos(13.0), watchos(7.0))` — and in the macOS SDK an unlisted platform is available, not excluded: `XCTMetric.h` marks the members that really are macOS-unavailable with an explicit `API_UNAVAILABLE(macos)`, and `XCTHitchMetric` lists macOS 26. The metrics compile and run in a macOS test target; the doc omission is an artefact of the macro.

## Xcode baselines, and why not to gate CI on them

A baseline is a value plus a maximum standard deviation: _"The test fails if the recorded metric is worse than the baseline value by more than the maximum standard deviation."_ Set one from the gutter icon beside the `measure` call.

Apple documents **nothing** about where baselines are stored, how they are keyed, or how they behave in CI. The commonly cited `.xcbaseline` path keyed by hardware model is third-party knowledge. For anything automated, emit the numbers and diff them yourself — [review.md](review.md) has a format.

## From the command line

```bash
xcodebuild test -scheme MyApp -only-testing MyAppTests/PerfTests \
  -resultBundlePath /tmp/perf.xcresult
xcrun xcresulttool ...    # see `man xcresulttool`
```

The bundle extension is `.xcresult` (Apple's own article misspells it `.xcresults`). Apple publishes no schema for extracting performance measurements from it, so treat parsing as your own problem.

## Signposts scope, samplers measure

`OSSignposter` (macOS 12+) marks the region you care about; the sampler tells you what ran inside it:

```swift
import OSLog
let signposter = OSSignposter(subsystem: "com.example.MyApp", category: .pointsOfInterest)

let state = signposter.beginInterval("import")
defer { signposter.endInterval("import", state) }
```

An interval is exactly one begin and one end, and you must keep the returned `OSSignpostIntervalState`. `withIntervalSignpost(_:id:around:)` does both for a block. In Instruments, secondary-click the region in the Points of Interest track to set the inspection range, which limits the detail view to that interval — the cleanest way to profile one operation rather than one time window.
