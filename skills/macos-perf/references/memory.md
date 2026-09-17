# Memory

## What counts

An app's **footprint is dirty plus compressed memory**. Clean memory — read-only file mappings, framework `DATA_CONST` sections, texture and audio assets mapped from disk — can be evicted and reloaded, so it does not count. Dirty memory is anything the app has written to: allocations, decoded image buffers, framework data sections. Runtime tricks like swizzling can dirty a page that would otherwise be clean.

`vmmap --summary` reports the **precompressed** size of swapped data, not what it compressed down to. That trips people up when the arithmetic does not add up.

## macOS is not iOS here — this changes the whole verdict

Apple's memory-termination machinery covers "iOS, iPadOS, tvOS, visionOS, and watchOS". macOS is absent from that list, and Apple states elsewhere that macOS "doesn't issue memory warnings or out-of-memory terminations".

So on macOS there is **no jetsam, no per-process memory limit, no low-memory warning, and no memory-gauge red zone to stay out of**. None of the jetsam event report material applies. The consequence of a large footprint is compression, then swap, then system-wide memory pressure and a machine that feels slow — a worse user experience rather than a crash, and one that shows up in the user's whole session rather than in your app's logs. Say that in the report instead of borrowing an iOS threshold that does not exist here.

## Leaked versus abandoned — different bugs, different tools

Apple splits heap memory three ways:

- **Useful** — reachable and will be used again.
- **Abandoned** — reachable and could be used, but never will be. Over-aggressive caching, expensive data parked on a singleton. It counts against footprint and is simply wasted.
- **Leaked** — unreachable and can never be used again. A lost last pointer, or a reference cycle.

**`leaks` and the Leaks instrument only find the unreachable kind.** Abandoned memory grows the footprint without ever appearing in leak detection, which is why "no leaks found" and "memory keeps climbing" are perfectly consistent findings. Say which kind you looked for.

## Finding leaks

```bash
leaks <pid>
leaks <pid> --traceTree       # what references a given address
leaks <pid> --referenceTree   # top-down reference tree with roots
heap <pid>                    # live allocation counts and sizes by class
vmmap --summary <pid>         # regions: dirty, swapped, clean
malloc_history <pid> <addr> --fullStacks
```

Set `MallocStackLogging` in the environment first and `leaks` reports where each buffer was allocated, which turns an address into a location in your code. Apple's other documented malloc debugging variables: `MallocStackLoggingNoCompact` (log every allocation regardless of size or lifetime), `MallocScribble` (fill freed bytes with `0x55`), `MallocPreScribble` (fill newly allocated bytes with `0xAA`), `MallocGuardEdges` (guard pages around large allocations), and `MallocCheckHeapStart` / `MallocCheckHeapEach` for periodic heap validation.

Which tool answers which question: allocation backtrace → `malloc_history`; what holds a reference → `leaks`; region and instance sizes → `vmmap` and `heap`.

## Finding abandoned memory — generational analysis

The only reliable method, and it is a workflow rather than a command:

1. Launch the app and get it to a steady state.
2. In the Allocations instrument, click **Mark Generation**.
3. Perform the operation under suspicion.
4. Click **Mark Generation** again. Repeat the operation several times, marking between each.

Allocations that persist across every generation are abandoned. The tell is a step pattern: memory that rises with each repetition and never comes back down. Two repetitions cannot distinguish a cache filling up from a genuine accumulation — do at least four.

`heap --diffFrom` compares two memory graphs for the same shape of answer from the command line. Export a graph with File > Export Memory Graph, or enable stack traces first by checking **Malloc Stack** in the scheme's Diagnostics settings.

## The per-process number to quote

`footprint --pid <pid>` is Apple's own accounting and the closest thing to what the user sees in Activity Monitor. Apple documents its flags only in `man footprint`, so check there rather than guessing. Note that Apple defines Activity Monitor's pane-level figures — App Memory, Wired, Compressed, Cached Files, Swap Used — but never publishes a definition of the per-process Memory column, so do not assert an exact equivalence between it and any tool's output.
