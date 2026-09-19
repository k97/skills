# k97/skills

Agent Skills for AI coding agents, built on the [Agent Skills](https://agentskills.io) open standard — installable in Claude Code, Cursor, Codex, Copilot, Gemini CLI, and ~20 other agents.

| Skill | What it does |
| --- | --- |
| [**`stage-gate`**](skills/stage-gate/) | Quality gates at the three feature-cycle boundaries: plan review (`--plan`), diff review (`--dev`), post-merge hygiene (`--release`). Karpathy-style guardrails + memory-file (CLAUDE.md / AGENTS.md) progressive disclosure. Agent-agnostic. |
| [**`apple-appicon`**](skills/apple-appicon/) | Apple platform app icons (iOS, iPadOS, macOS, visionOS) from one source image, HIG as the north star. Validates the source, then generates appiconsets, `.icns`, visionOS stacks, and Tauri's full set with the dock-icon margin fix. Agent-agnostic. |
| [**`discoverability`**](skills/discoverability/) | Technical SEO audit → GEO (AI-citation) review → applies the fixes in your codebase. Ships scripts that trace redirect loops and lint JSON-LD. |
| [**`macos-app-performance`**](skills/macos-app-performance/) | Benchmark and review one macOS app against Apple's published thresholds — hangs, responsiveness, launch, CPU, memory, energy — with an optional baseline for regression checks. Careful about which Apple guidance is macOS and which is iOS-only. |

## Install

```bash
npx skills add k97/skills --list                  # see what's in here
npx skills add k97/skills --skill stage-gate      # install one skill
```

Claude Code users can also install the whole set as a plugin:

```bash
/plugin marketplace add k97/skills
/plugin install k97-skills@k97-skills
```

`skills add` takes the **repo path**, not the skill name. Requirements vary per skill; `stage-gate` needs only `git`. `apple-appicon` is fully native on macOS (Xcode Command Line Tools: `sips`, `iconutil`, `swift`); on Linux/Windows it says so up front and falls back to ImageMagick 7 + Tauri's own cross-platform CLI where it can. `discoverability` needs `curl` and Node 18+, with nothing to `npm install`. `macos-app-performance` is macOS-only by nature; the command-line half needs nothing installed, while Instruments, `xctrace` and XCTest metrics need full Xcode rather than the Command Line Tools, and the skill checks before promising a trace.

> **Claude Code, in a project with no `.claude/` directory yet:** the CLI writes the canonical copy to `.agents/skills/` and skips the `.claude/skills/` symlink, even though it reports "Installing to: … Claude Code". Run `mkdir -p .claude` first, or install globally with `-g`, and the symlink appears as expected.

Or copy a skill in manually:

```bash
git clone https://github.com/k97/skills /tmp/k97-skills

mkdir -p .claude/skills                                  # this project only
cp -r /tmp/k97-skills/skills/stage-gate .claude/skills/

mkdir -p ~/.claude/skills                                # or: everywhere
cp -r /tmp/k97-skills/skills/stage-gate ~/.claude/skills/
```

Start a new session and `/stage-gate` is available.

---

# stage-gate

One skill, three gates, each run at the boundary it is named after: after **planning**, after **development**, after **merge or release**. It combines two ideas that turn out to feed each other: [Karpathy-style guardrails](https://github.com/forrestchang/andrej-karpathy-skills) against common LLM coding mistakes, and `reclaude`-style [progressive-disclosure](https://agentskills.io) hygiene for CLAUDE.md.

## Usage

```bash
/stage-gate --plan                    # gate the plan before any code is written
/stage-gate --plan docs/plans/x.md    # ...or point it at a specific plan file
/stage-gate --dev                     # review the diff before push or PR
/stage-gate --release                 # after merge: capture lessons, keep CLAUDE.md lean and armed
/stage-gate                           # no flag: infers the gate from git state and context
```

It also triggers on plain language: _"review my plan"_, _"gate this diff"_, _"is this overcomplicated"_, _"post-merge hygiene"_, _"capture lessons"_, _"CLAUDE.md is too long"_.

### Prompts that load it

Copy-paste, or say something close. You do not need the flags.

**Gate the plan — after planning, before code**

> Review my plan before we build. Check `docs/plans/2026-08-30-csv-export.md` — anything I haven't stated? What assumptions is this plan resting on?

**Gate the diff — after coding, before push**

> Gate this diff before I push. Is this overcomplicated? Did I touch more than the request needed?

**Hygiene — after merge or release**

> Verify and release. _(runs `--dev` then `--release`)_ Wrap up this feature. Capture what this cycle taught us. CLAUDE.md is getting long.

**Day zero, on a fresh repo**

> Set up CLAUDE.md for this repo. _(run right after `/init`)_

The plan gate takes a path, so _"review the plan at `docs/plans/x.md`"_ targets a file directly rather than whatever is left in the conversation.

You should not have to remember any of that, though. `--release` installs a four-line **gate-trigger block** into your CLAUDE.md, naming the three boundaries — so the gates fire from where the work actually is, not from you recalling the right phrase at the moment the work looks done.

## Example prompts

One feature cycle, three gates:

**After planning — before any code:**

> Here's my plan for the CSV export feature. `/stage-gate --plan`

> Before I build this: check my plan for unstated assumptions, and make sure every step has a success criterion you could actually run.

**After coding — before push or PR:**

> `/stage-gate --dev`

> Review my diff before I push — is any of this overcomplicated? Did I change anything the task didn't need?

> Gate this branch against main.

**After merge or release:**

> We just merged the export feature. `/stage-gate --release`

> Capture what we learned this cycle and check CLAUDE.md is still lean.

**Day zero — new repo or right after `/init`:**

> Set up CLAUDE.md for this repo.

> I just ran `/init` and the generated CLAUDE.md is huge. `/stage-gate --release`

**When you're not sure which gate applies:**

> `/stage-gate` — it reads the git state and the conversation, tells you which gate it picked, and runs it.

## The three gates

| Flag | Gate | When | Writes |
| --- | --- | --- | --- |
| `--plan` | Plan review — assumptions surfaced, scope traceable, success criteria runnable | after planning, before code | no |
| `--dev` | Diff review — Simplicity / Surgical / Verification lenses over every hunk | before push or PR | no |
| `--release` | Hygiene — capture the cycle's lessons into `.claude/rules/`, keep CLAUDE.md lean | after merge or release | yes |

There is deliberately no `--full`: the gates run at different moments in the cycle, so chaining them never matches a real invocation.

`--release` also doubles as the day-zero bootstrap: run it once right after `/init` — it creates CLAUDE.md from the target shape if missing, prunes the auto-generated bloat if not, and seeds `.claude/rules/coding-guardrails.md` from the start.

**Agent-agnostic**, like the [upstream Karpathy guidelines](https://github.com/forrestchang/andrej-karpathy-skills): the skill format is the cross-agent [Agent Skills](https://agentskills.io) standard, and the hygiene gate detects and targets whichever memory file the repo uses — `CLAUDE.md` (Claude Code), `AGENTS.md` (Codex, Cursor, Antigravity), `GEMINI.md` (Gemini CLI), or `.github/copilot-instructions.md` (GitHub Copilot) — same thresholds, same refactor, rules written to that agent's location. Multi-agent repos with a canonical `AGENTS.md` and symlinks get edited at the canonical file only.

What the skill needs from its host — memory file, rules location, a fresh reviewer, invocation, init command, argument passing — is stated once as a capability matrix in [`references/agents.md`](skills/stage-gate/references/agents.md), with a detect-don't-assume rule so agents outside the table degrade rather than break. Be aware that **Claude Code is the only column exercised end to end**; the rest are written from each agent's documented behaviour and should be read as designed-for, not proven.

The feedback loop is the point: findings that keep recurring in `--dev` reviews are exactly what `--release` distills into `.claude/rules/`, and the hygiene pass keeps those rules lean enough that they stay loaded and get read. The `--release` gate is built to no-op fast (line-count triage first), so running it every cycle costs almost nothing.

The preventive half of the guardrails belongs in your project's CLAUDE.md — the hygiene gate checks it is there and adds `.claude/rules/coding-guardrails.md` if not. The skill gates compliance at the boundaries; it does not replace always-on guidelines.

## Credits

Assembled by [@k97](https://github.com/k97), drawing on:

- **[forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)** (MIT) — derived from [Andrej Karpathy's observations](https://x.com/karpathy/status/2015883857489522876) on LLM coding pitfalls; the source of the `--plan` and `--dev` lenses
- **`reclaude`** — the progressive-disclosure CLAUDE.md refactoring workflow behind `--release`

`stage-gate` adds the three-boundary framing, gate inference from git state, and the `--dev` → `--release` lessons loop. For narrower single-purpose takes on each gate, see [garrytan/gstack](https://github.com/garrytan/gstack) (`plan-eng-review`, `review`) and [AlexZio00/claude-code-skills](https://github.com/AlexZio00/claude-code-skills) (`pre-push`, `goal-lock`, `doc-drift`).

---

# apple-appicon

One source image in, HIG-correct icon sets out — for **iOS, iPadOS, macOS, and visionOS**, with first-class **Tauri** support. Apple's [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/app-icons) are the north star: full-bleed unmasked squares where the system applies the mask (iOS, iPadOS, visionOS), Apple's rounded-rect-with-margins treatment baked in where it doesn't (legacy macOS `.icns`).

Everything runs on tools already on a dev Mac — `sips`, `iconutil`, and a small Swift/CoreGraphics utility — so there is nothing to install.

**Agent-agnostic**, like the rest of this repo: the skill format is the cross-agent [Agent Skills](https://agentskills.io) standard, and the workflow needs nothing beyond a shell — no Claude Code-specific variables or tools. Commands reference `<skill-dir>` generically (Claude Code resolves it via `${CLAUDE_SKILL_DIR}`; other agents use the installed skill's directory). The one optional extra: agents with image input visually check the artwork against HIG advisories (pre-rounded corners, thin lines, text, photos); agents without it hand that checklist to you instead.

Platform-wise it degrades explicitly rather than failing mid-run: invoked on Linux or Windows, the first thing the agent does is say what works there — Tauri projects keep full support including the `.icns` (Tauri's CLI is Rust and cross-platform), asset-catalog PNGs fall back to documented ImageMagick 7 equivalents, and only a bare `.icns` outside Tauri genuinely needs a Mac, `png2icns`, or CI.

## Usage

```bash
/apple-appicon ./artwork/logo.png                      # detect the project, generate for its targets
/apple-appicon ./logo.png --platform tauri             # Tauri: full set + macOS dock-icon fix
/apple-appicon ./logo.png --platform macos --out ./out # one platform, custom destination
```

It also triggers on plain language: _"generate app icons from this image"_, _"make an .icns"_, _"our Tauri dock icon looks huge"_, _"App Store icon"_.

Example prompts:

> Here's our logo at `design/icon-1024.png` — generate the app icons for this Tauri app.

> Make an AppIcon.appiconset for iOS with dark and tinted variants from `logo.png`.

> Our dock icon fills the whole tile and looks wrong next to other Mac apps. Fix it.

## The workflow

| Step | What happens |
| --- | --- |
| **Validate** | `scripts/validate-source.sh` gates the source: square aspect, ≥1024 px, alpha channel, sRGB/P3, 8-bit. Hard failures stop the run with copy-paste fixes (centre-crop vs transparent pad). |
| **Look** | The agent views the artwork and flags HIG problems a script can't see: pre-rounded corners (double-masking), thin lines that die at 16 px, text, photos. |
| **Generate** | Per platform: `AppIcon.appiconset` (1024 single-size, dark/tinted variants), `.icns` via `iconutil`, visionOS `solidimagestack`, or `tauri icon` plus a rebuilt margined `.icns`. |
| **Verify** | Pixel sizes re-checked, alpha confirmed stripped on the App Store icon, outputs viewed, and a table of files → where they're wired. |

**Why the macOS treatment matters:** `tauri icon` (and most generators) put the full-bleed source straight into `icon.icns`, which renders as an oversized square in the Dock. Apple icons carry ~10% margins inside a rounded rectangle (824 px content box on the 1024 canvas, r ≈ 185 px, subtle shadow). `scripts/appicon.swift macos` applies exactly that before the `.icns` is compiled — full-bleed everywhere else, margined on macOS, per the HIG.

## The scripts

```bash
cd skills/apple-appicon

# Gate any candidate source image (exit 1 on blocking problems)
bash scripts/validate-source.sh ../logo.png

# Transforms, all 8-bit sRGB PNG out:
swift scripts/appicon.swift resize  in.png out.png 512          # exact square resize
swift scripts/appicon.swift flatten in.png out.png 1024 "#0A84FF" # opaque + alpha stripped (App Store)
swift scripts/appicon.swift pad     in.png out.png              # square-ify on transparent canvas
swift scripts/appicon.swift macos   in.png out.png              # Apple macOS margins + corners + shadow
```

Scope notes: watchOS/tvOS and Icon Composer's layered Liquid Glass `.icon` bundles are out of scope in v1 (the skill generates the flat baseline and says so). **Roadmap:** Flutter, React Native, and Ionic/Capacitor integrations; until then the Apple-side assets drop into those frameworks' iOS/macOS folders unchanged.

## Credits

Assembled by [@k97](https://github.com/k97), drawing on:

- **[Apple HIG · App icons](https://developer.apple.com/design/human-interface-guidelines/app-icons)** and the **[Tauri v2 icon docs](https://v2.tauri.app/develop/icons/)** — the specs, distilled into `references/`
- **[brianlovin/claude-config](https://www.skills.sh/brianlovin/claude-config/favicon)** (`favicon`) — the validate → generate → wire-up workflow shape
- **[michaelboeding/skills](https://www.skills.sh/michaelboeding/skills/icon-generation)** (`icon-generation`) — prior art for agent-driven icon pipelines

`apple-appicon` adds the HIG-first shape rules per platform, the source-image gate, and the Tauri dock-icon fix.

---

# discoverability

Takes a web project from **audit → AI-citation review → applied fixes** in one workflow. Built for Next.js / TypeScript by default, and adapts to whatever framework it finds.

Unlike prompt-only SEO skills, it ships **three dependency-free scripts** so the audit produces evidence rather than guesses: a live redirect-chain tracer, a JSON-LD linter, and a metadata auditor that checks canonical hosts against the host your site _actually serves_.

## Usage

```bash
/discoverability ./my-app                          # audit → GEO review → apply fixes (default)
/discoverability ./my-app --audit                  # technical audit only, no code changes
/discoverability ./my-app --geo                    # AI-citation review only
/discoverability --fix                             # apply fixes from reports already in context
/discoverability ./my-app --routes /,/pricing      # narrow the scope
```

It also triggers on plain language: _"run an SEO audit"_, _"why aren't we cited by AI"_, _"improve our schema"_, _"we have a redirect loop"_, _"www vs apex"_.

Example prompts:

> Audit this repo's SEO — the live site is example.com. `--audit`

> Why isn't ChatGPT citing us? Run a GEO review on ./my-app.

> Users are hitting ERR_TOO_MANY_REDIRECTS on www — trace it and fix it.

If you keep a product brief at `.agents/product-marketing.md` or `.claude/product-marketing.md`, the skill reads it before asking you anything.

## The three phases

| Phase | Flag | What it does | Touches code |
| --- | --- | --- | --- |
| **1 · Technical audit** | `--audit` | Metadata, robots, sitemap, JSON-LD, on-page, canonical chains — plus a live redirect trace across apex, www, and your real routes. Findings grouped by severity with a prioritised plan. | no |
| **2 · GEO review** | `--geo` | Whether ChatGPT, Perplexity, Gemini, and Claude can reach, parse, and cite you. Bot access, schema completeness, content tactics. | no |
| **3 · Fix** | `--fix` | Applies the findings in your codebase, then re-runs the scripts to verify. Leaves the commit to you. | yes |
| **All three** | `--full` _(default)_ | 1 → 2 → 3. | yes |

## The scripts

They run standalone, so you can use them without the skill:

```bash
cd skills/discoverability

# Redirect chains for apex + www + each route. Catches ERR_TOO_MANY_REDIRECTS
# before your users do. Loops often hide on deep paths, not on "/".
bash scripts/redirect-trace.sh example.com /pricing /blog

# Extract, parse, and lint every server-rendered JSON-LD block.
node scripts/extract-jsonld.mjs https://example.com

# Title, description, canonical, OG/Twitter, robots, h1, image alt.
node scripts/audit-meta.mjs https://example.com/pricing
node scripts/audit-meta.mjs out/pricing.html --base https://example.com
```

Each exits non-zero on an error-level finding, so they drop straight into CI. The Node scripts take `--json`.

**What they catch that a prompt won't:** relative URLs in JSON-LD, `aggregateRating` without a review count, breadcrumb positions out of order, two canonical tags on one page, a page that is both `noindex` and canonical, a title whose template suffix collides with itself, and — the big one — a canonical host that disagrees with the host the request lands on.

**What they can't see:** anything injected by client-side JavaScript. They read server-rendered HTML, same as `web_fetch`. The skill says so explicitly rather than reporting "no schema found."

## Why the redirect check exists

The most common way to take a site fully down on deploy day is an app-level host redirect (`www`↔apex, `http`↔`https`, trailing slash) that duplicates one your hosting platform already performs. The two ping-pong, and every URL returns `ERR_TOO_MANY_REDIRECTS`.

It is invisible from source, because neither redirect is wrong on its own. `redirect-trace.sh` finds it, and the skill's hard rule is to _remove_ the app-level redirect rather than add another.

## A note on GEO claims

Plenty of SEO advice ranks schema types by "citation yield, per Princeton research." The [Princeton GEO paper](https://arxiv.org/abs/2311.09735) (Aggarwal et al., KDD 2024) tested nine **content** tactics across 10,000 queries. Adding statistics, quotations, and cited sources lifted visibility by up to 40%. Keyword stuffing did nothing. It never tested schema types and established no ordering among them.

This skill cites the paper for what it found, treats schema as a cheap correctness measure rather than a measured ranking lever, and does not project traffic numbers it cannot observe.

## Credits

Assembled and extended by [@k97](https://github.com/k97), drawing on:

- **[coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills)** — `seo-audit`, `ai-seo`, `schema`, `cro`
- **[ReScienceLab/opc-skills](https://github.com/ReScienceLab/opc-skills)** — `seo-geo`

`discoverability` adds the live redirect and canonical-host tooling, the JSON-LD linter, and the in-codebase fix phase. For narrower single-purpose tools, the collections above are the place to look.

---

# macos-app-performance

Points at **one app** and answers whether it is fast enough, against **Apple's own published thresholds** — then says what to fix first. Not whole-machine triage: the subject is an app you are building or one you are evaluating.

It exists because the numbers are the easy part and the judgement is not. Apple publishes actual thresholds — 250 ms before a stall counts as a hang, 500 ms before it is a "proper" one, 5 ms of main-thread work during continuous interaction, one idle wakeup per second — and most profiling advice quotes none of them. Worse, much of what circulates as "Apple's performance guidance" is iOS-only and silently wrong on a Mac: the 400 ms launch target is an iOS figure justified by the iOS launch animation; jetsam, memory limits and low-memory warnings do not exist on macOS at all; the Organizer hitch-rate scale is iOS and iPadOS only. This skill carries the thresholds that do apply and names the ones that do not.

## Usage

```bash
/macos-app-performance MyApp                # full review: hangs, CPU, memory, energy
/macos-app-performance MyApp --hang         # beachballs: is the main thread busy or blocked
/macos-app-performance MyApp --cpu          # where the CPU goes, and whether that work is needed
/macos-app-performance MyApp --launch       # time to first frame
/macos-app-performance MyApp --memory       # footprint, growth, leaked vs abandoned
/macos-app-performance MyApp --energy       # wakeups, QoS, sleep assertions, thermals
/macos-app-performance MyApp --baseline     # record numbers, or compare against a recorded set
```

Plain language works: _"profile my app"_, _"why does my app beachball"_, _"is my app leaking"_, _"did this release get slower"_, _"my Mac app drains battery"_, _"performance review before I ship"_.

### Prompts that load it

> My SwiftUI app beachballs for about a second whenever you open the library view. I can see it in Instruments but the Time Profiler stacks are almost empty during the freeze — what am I missing?

> Tauri app, memory goes from 180MB to about 900MB over a day of use and never comes back. `leaks` says nothing is leaking. Is that actually fine?

> We shipped 2.1 last week and a few users say it feels slower than 2.0. How would I establish whether that's real before I start changing things?

## Example prompts

One app, judged against Apple's numbers — each flag is a question:

**Before shipping — the full review:**

> We cut 2.2 on Friday. Review the release build of MyApp against Apple's thresholds and tell me what to fix first. `/macos-app-performance MyApp`

> Record this release's numbers so the next one has something to compare against. `/macos-app-performance MyApp --baseline`

**Beachballs and hangs:**

> MyApp shows the spinning cursor for a couple of seconds after I paste a large document. Is the main thread busy or blocked, and on what?

**CPU:**

> Activity Monitor shows MyApp at 30% CPU while it sits idle in the background. Find what is running and whether it needs to run at all.

**Launch:**

> Cold launch of MyApp feels slow on an M1 Air. Measure time to first frame and say whether the cost is before or after `main`.

**Memory:**

> Footprint over an hour of normal use, and whether the growth is leaked or abandoned. `/macos-app-performance MyApp --memory`

**Energy:**

> MyApp drains the battery overnight with the lid closed. Which assertion is holding the machine awake, and how many idle wakeups per second is it taking?

**Regression check against a baseline:**

> Compare this build against the baseline we recorded for 2.1. Tell me what actually moved, not what is inside run-to-run noise.

## The workflow

Establish the subject, make the measurement valid, measure, then judge.

| Step | What happens |
| --- | --- |
| Subject | Detect Xcode / SwiftPM / Tauri / Electron; enumerate the app's processes, because the one doing the work is rarely the one on the bundle |
| Validity | Release build, Apple's accuracy settings, repetitions with the first discarded, thermal state checked before **and after** |
| Measure | Hangs first (Apple's own priority), then CPU, memory, energy |
| Review | Numbers judged against Apple's thresholds, findings ranked by impact, optional baseline for next time |

## What it gets right that the folklore doesn't

- **Hangs first.** Apple's guidance, not a preference: fixing hangs tends to fix rendering stutter as a side effect.
- **Busy vs. blocked main thread** is the triage split that decides the tool. Empty stacks during a freeze mean _blocked_, and a CPU profiler will never show you why — that needs thread states, which is the System Trace template from the command line.
- **Prefer CPU Profiler to Time Profiler.** Apple's current guidance: Time Profiler samples on a timer and over-represents periodic work, and under-weights faster cores — which matters on Apple Silicon.
- **A leak and abandoned memory are different bugs.** `leaks` only finds unreachable memory. Memory that climbs forever while `leaks` reports nothing is _abandoned_, and only generational analysis finds it.
- **`instruments` is gone** — deprecated in Xcode 12 and absent from current Xcode. `xcrun xctrace` replaces it, and its documentation is `man xctrace`, not a web page.
- **Apple's docs are readable.** Appending `.md` to any `developer.apple.com/documentation/` URL returns the article source plus a per-platform `availability` block — which is how you check whether an API exists on macOS before recommending it.

## What it will not do

Measure and review, not remediate: it produces numbers, judges them, ranks what to fix, and stops. It will not tune the machine to flatter a benchmark, and it refuses a baseline comparison whose conditions don't match rather than reporting a regression that is really a different laptop.

## Credits

Rebuilt by [@k97](https://github.com/k97), grounded in Apple's own material:

- **[Improving app responsiveness](https://developer.apple.com/documentation/xcode/improving-app-responsiveness)**, **[Understanding hangs in your app](https://developer.apple.com/documentation/xcode/understanding-hangs-in-your-app)**, **[Understanding hitches in your app](https://developer.apple.com/documentation/xcode/understanding-hitches-in-your-app)** — the responsiveness thresholds
- **[Writing and running performance tests](https://developer.apple.com/documentation/xcode/writing-and-running-performance-tests)** — measurement accuracy settings, XCTest metrics, baselines
- **[Energy Efficiency Guide for Mac Apps](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/power_efficiency_guidelines_osx/index.html)** (archived) — App Nap, QoS, wakeups, Energy Impact
- **WWDC25 session 308** (CPU Profiler over Time Profiler), **WWDC24 session 10173** (leaked vs. abandoned), **WWDC23 session 10248** (hang severity)
- The scope and framing began as the `macos-perf` skill in **[alphaonedev/openclaw-graph](https://www.skills.sh/alphaonedev/openclaw-graph/macos-perf)**, since defunct — little of it survives, and the name was dropped because it collides with whole-machine skills of the same name.

---

## Repo layout

```
k97/skills
├── skills.sh.json                    # groups the skills.sh repo page
├── .claude-plugin/                   # marketplace.json for /plugin marketplace add
├── evals/                            # one `claude plugin eval` case per skill (format per docs; not yet run — eval is early access on Claude Code 2.1.223)
├── CHANGELOG.md
└── skills/
    ├── stage-gate/
    │   ├── SKILL.md
    │   └── references/
    │       ├── plan-gate.md          # --plan checklist
    │       ├── diff-review.md        # --dev lenses
    │       └── memory-hygiene.md     # --release triage + refactor
    ├── apple-appicon/
    │   ├── SKILL.md
    │   ├── references/
    │   │   ├── apple-hig.md          # per-platform geometry, mask rules, advisories
    │   │   ├── platform-recipes.md   # commands + Contents.json templates
    │   │   └── tauri.md              # tauri icon + dock-icon fix + roadmap
    │   └── scripts/
    │       ├── validate-source.sh    # the source-image gate
    │       └── appicon.swift         # resize / flatten / pad / macos treatments
    ├── discoverability/
    │   ├── SKILL.md
    │   ├── references/
    │   │   ├── technical-audit.md    # full Phase 1 checklist
    │   │   ├── geo.md                # Phase 2 depth + bot table
    │   │   └── schema-recipes.md     # copy-paste JSON-LD, lint-clean
    │   └── scripts/
    │       ├── redirect-trace.sh
    │       ├── extract-jsonld.mjs
    │       └── audit-meta.mjs
    └── macos-app-performance/
        ├── SKILL.md
        └── references/
            ├── measurement.md        # validity: build settings, repetitions, thermal gate, XCTest
            ├── instruments.md        # xctrace CLI, template choice, CPU Profiler vs Time Profiler
            ├── responsiveness.md     # hang thresholds, busy vs blocked, frame budget, launch
            ├── cpu.md                # sample, hot paths, QoS placement, multi-process apps
            ├── memory.md             # footprint, leaked vs abandoned, generational analysis
            ├── energy.md             # wakeups, QoS, App Nap, sleep assertions, thermal state
            └── review.md             # report structure and baseline format
```

Each `SKILL.md` carries only the six [Agent Skills spec](https://agentskills.io/specification) frontmatter fields, so `npx skills-ref validate skills/<name>` passes.

The registry CLI walks root `SKILL.md`, `skills/<name>/SKILL.md`, or `skills/<category>/<name>/SKILL.md`. Anything else is invisible to `npx skills add`.

Skills are structured around [progressive disclosure](https://agentskills.io), so each costs almost nothing until you use it:

| Layer | When it loads | Cost |
| --- | --- | --- |
| `description` | every session, for every installed skill | ~96 tokens |
| `SKILL.md` body | on invocation, then stays all session | ~1,285 tokens |
| `references/*.md` | only when a phase reads one | 0 until read |
| `scripts/*` | executed, never read into context | 0 — only their output counts |

So a `discoverability --audit` run never pays for the GEO reference, and no run ever pays for the ~4,700 tokens of script source. The scripts print findings rather than confirmations for the same reason: their stdout is the part that lands in the context window.

## License

[MIT](LICENSE) © 2026 Karthik ([@k97](https://github.com/k97))
