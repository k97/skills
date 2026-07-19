# k97/skills

Agent Skills for AI coding agents, built on the [Agent Skills](https://agentskills.io) open standard — installable in Claude Code, Cursor, Codex, Copilot, Gemini CLI, and ~20 other agents.

| Skill | What it does |
|---|---|
| [**`phase-gate`**](skills/phase-gate/) | Quality gates at the three feature-cycle boundaries: plan review (`--plan`), diff review (`--dev`), post-merge hygiene (`--release`). Karpathy-style guardrails + memory-file (CLAUDE.md / AGENTS.md) progressive disclosure. Agent-agnostic. |
| [**`codebase-seo`**](skills/codebase-seo/) | Technical SEO audit → GEO (AI-citation) review → applies the fixes in your codebase. Ships scripts that trace redirect loops and lint JSON-LD. |

## Install

```bash
npx skills add k97/skills --list                  # see what's in here
npx skills add k97/skills --skill phase-gate      # install one skill
```

`skills add` takes the **repo path**, not the skill name. Requirements vary per skill; `phase-gate` needs only `git`. `codebase-seo` needs `curl` and Node 18+, with nothing to `npm install`.

> **Claude Code, in a project with no `.claude/` directory yet:** the CLI writes the canonical copy to `.agents/skills/` and skips the `.claude/skills/` symlink, even though it reports "Installing to: … Claude Code". Run `mkdir -p .claude` first, or install globally with `-g`, and the symlink appears as expected.

Or copy a skill in manually:

```bash
git clone https://github.com/k97/skills /tmp/k97-skills

mkdir -p .claude/skills                                  # this project only
cp -r /tmp/k97-skills/skills/phase-gate .claude/skills/

mkdir -p ~/.claude/skills                                # or: everywhere
cp -r /tmp/k97-skills/skills/phase-gate ~/.claude/skills/
```

Start a new session and `/phase-gate` is available.

---

# phase-gate

One skill, three gates, each run at the boundary it is named after: after **planning**, after **development**, after **merge or release**. It combines two ideas that turn out to feed each other: [Karpathy-style guardrails](https://github.com/forrestchang/andrej-karpathy-skills) against common LLM coding mistakes, and `reclaude`-style [progressive-disclosure](https://agentskills.io) hygiene for CLAUDE.md.

## Usage

```bash
/phase-gate --plan       # gate the plan in context before any code is written
/phase-gate --dev        # review the diff before push or PR
/phase-gate --release    # after merge: capture lessons, keep CLAUDE.md lean
/phase-gate              # no flag: infers the gate from git state and context
```

It also triggers on plain language: *"review my plan"*, *"gate this diff"*, *"is this overcomplicated"*, *"post-merge hygiene"*, *"capture lessons"*, *"CLAUDE.md is too long"*.

## Example prompts

One feature cycle, three gates:

**After planning — before any code:**

> Here's my plan for the CSV export feature. `/phase-gate --plan`

> Before I build this: check my plan for unstated assumptions, and make sure every step has a success criterion you could actually run.

**After coding — before push or PR:**

> `/phase-gate --dev`

> Review my diff before I push — is any of this overcomplicated? Did I change anything the task didn't need?

> Gate this branch against main.

**After merge or release:**

> We just merged the export feature. `/phase-gate --release`

> Capture what we learned this cycle and check CLAUDE.md is still lean.

**Day zero — new repo or right after `/init`:**

> Set up CLAUDE.md for this repo.

> I just ran `/init` and the generated CLAUDE.md is huge. `/phase-gate --release`

**When you're not sure which gate applies:**

> `/phase-gate` — it reads the git state and the conversation, tells you which gate it picked, and runs it.

## The three gates

| Flag | Gate | When | Writes |
|---|---|---|---|
| `--plan` | Plan review — assumptions surfaced, scope traceable, success criteria runnable | after planning, before code | no |
| `--dev` | Diff review — Simplicity / Surgical / Verification lenses over every hunk | before push or PR | no |
| `--release` | Hygiene — capture the cycle's lessons into `.claude/rules/`, keep CLAUDE.md lean | after merge or release | yes |

There is deliberately no `--full`: the gates run at different moments in the cycle, so chaining them never matches a real invocation.

`--release` also doubles as the day-zero bootstrap: run it once right after `/init` — it creates CLAUDE.md from the target shape if missing, prunes the auto-generated bloat if not, and seeds `.claude/rules/coding-guardrails.md` from the start.

**Agent-agnostic**, like the [upstream Karpathy guidelines](https://github.com/forrestchang/andrej-karpathy-skills): the skill format is the cross-agent [Agent Skills](https://agentskills.io) standard, and the hygiene gate detects and targets whichever memory file the repo uses — `CLAUDE.md` (Claude Code), `AGENTS.md` (Codex, Cursor, Antigravity), `GEMINI.md` (Gemini CLI), or `.github/copilot-instructions.md` (GitHub Copilot) — same thresholds, same refactor, rules written to that agent's location. Multi-agent repos with a canonical `AGENTS.md` and symlinks get edited at the canonical file only.

The feedback loop is the point: findings that keep recurring in `--dev` reviews are exactly what `--release` distills into `.claude/rules/`, and the hygiene pass keeps those rules lean enough that they stay loaded and get read. The `--release` gate is built to no-op fast (line-count triage first), so running it every cycle costs almost nothing.

The preventive half of the guardrails belongs in your project's CLAUDE.md — the hygiene gate checks it is there and adds `.claude/rules/coding-guardrails.md` if not. The skill gates compliance at the boundaries; it does not replace always-on guidelines.

## Credits

Assembled by [@k97](https://github.com/k97), drawing on:

- **[forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)** (MIT) — derived from [Andrej Karpathy's observations](https://x.com/karpathy/status/2015883857489522876) on LLM coding pitfalls; the source of the `--plan` and `--dev` lenses
- **`reclaude`** — the progressive-disclosure CLAUDE.md refactoring workflow behind `--release`

`phase-gate` adds the three-boundary framing, gate inference from git state, and the `--dev` → `--release` lessons loop. For narrower single-purpose takes on each gate, see [garrytan/gstack](https://github.com/garrytan/gstack) (`plan-eng-review`, `review`) and [AlexZio00/claude-code-skills](https://github.com/AlexZio00/claude-code-skills) (`pre-push`, `goal-lock`, `doc-drift`).

---

# codebase-seo

Takes a web project from **audit → AI-citation review → applied fixes** in one workflow. Built for Next.js / TypeScript by default, and adapts to whatever framework it finds.

Unlike prompt-only SEO skills, it ships **three dependency-free scripts** so the audit produces evidence rather than guesses: a live redirect-chain tracer, a JSON-LD linter, and a metadata auditor that checks canonical hosts against the host your site *actually serves*.

## Usage

```bash
/codebase-seo ./my-app                          # audit → GEO review → apply fixes (default)
/codebase-seo ./my-app --audit                  # technical audit only, no code changes
/codebase-seo ./my-app --geo                    # AI-citation review only
/codebase-seo --fix                             # apply fixes from reports already in context
/codebase-seo ./my-app --routes /,/pricing      # narrow the scope
```

It also triggers on plain language: *"run an SEO audit"*, *"why aren't we cited by AI"*, *"improve our schema"*, *"we have a redirect loop"*, *"www vs apex"*.

Example prompts:

> Audit this repo's SEO — the live site is example.com. `--audit`

> Why isn't ChatGPT citing us? Run a GEO review on ./my-app.

> Users are hitting ERR_TOO_MANY_REDIRECTS on www — trace it and fix it.

If you keep a product brief at `.agents/product-marketing.md` or `.claude/product-marketing.md`, the skill reads it before asking you anything.

## The three phases

| Phase | Flag | What it does | Touches code |
|---|---|---|---|
| **1 · Technical audit** | `--audit` | Metadata, robots, sitemap, JSON-LD, on-page, canonical chains — plus a live redirect trace across apex, www, and your real routes. Findings grouped by severity with a prioritised plan. | no |
| **2 · GEO review** | `--geo` | Whether ChatGPT, Perplexity, Gemini, and Claude can reach, parse, and cite you. Bot access, schema completeness, content tactics. | no |
| **3 · Fix** | `--fix` | Applies the findings in your codebase, then re-runs the scripts to verify. Leaves the commit to you. | yes |
| **All three** | `--full` *(default)* | 1 → 2 → 3. | yes |

## The scripts

They run standalone, so you can use them without the skill:

```bash
cd skills/codebase-seo

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

It is invisible from source, because neither redirect is wrong on its own. `redirect-trace.sh` finds it, and the skill's hard rule is to *remove* the app-level redirect rather than add another.

## A note on GEO claims

Plenty of SEO advice ranks schema types by "citation yield, per Princeton research." The [Princeton GEO paper](https://arxiv.org/abs/2311.09735) (Aggarwal et al., KDD 2024) tested nine **content** tactics across 10,000 queries. Adding statistics, quotations, and cited sources lifted visibility by up to 40%. Keyword stuffing did nothing. It never tested schema types and established no ordering among them.

This skill cites the paper for what it found, treats schema as a cheap correctness measure rather than a measured ranking lever, and does not project traffic numbers it cannot observe.

## Credits

Assembled and extended by [@k97](https://github.com/k97), drawing on:

- **[coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills)** — `seo-audit`, `ai-seo`, `schema`, `cro`
- **[ReScienceLab/opc-skills](https://github.com/ReScienceLab/opc-skills)** — `seo-geo`

`codebase-seo` adds the live redirect and canonical-host tooling, the JSON-LD linter, and the in-codebase fix phase. For narrower single-purpose tools, the collections above are the place to look.

---

## Repo layout

```
k97/skills
└── skills/
    ├── phase-gate/
    │   ├── SKILL.md
    │   └── references/
    │       ├── plan-gate.md          # --plan checklist
    │       ├── diff-review.md        # --dev lenses
    │       └── memory-hygiene.md     # --release triage + refactor
    └── codebase-seo/
        ├── SKILL.md
        ├── references/
        │   ├── technical-audit.md    # full Phase 1 checklist
        │   ├── geo.md                # Phase 2 depth + bot table
        │   └── schema-recipes.md     # copy-paste JSON-LD, lint-clean
        └── scripts/
            ├── redirect-trace.sh
            ├── extract-jsonld.mjs
            └── audit-meta.mjs
```

The registry CLI walks root `SKILL.md`, `skills/<name>/SKILL.md`, or `skills/<category>/<name>/SKILL.md`. Anything else is invisible to `npx skills add`.

Skills are structured around [progressive disclosure](https://agentskills.io), so each costs almost nothing until you use it:

| Layer | When it loads | Cost |
|---|---|---|
| `description` | every session, for every installed skill | ~96 tokens |
| `SKILL.md` body | on invocation, then stays all session | ~1,285 tokens |
| `references/*.md` | only when a phase reads one | 0 until read |
| `scripts/*` | executed, never read into context | 0 — only their output counts |

So a `codebase-seo --audit` run never pays for the GEO reference, and no run ever pays for the ~4,700 tokens of script source. The scripts print findings rather than confirmations for the same reason: their stdout is the part that lands in the context window.

## License

[MIT](LICENSE) © 2026 Karthik ([@k97](https://github.com/k97))
