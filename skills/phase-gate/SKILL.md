---
name: phase-gate
description: >-
  Quality gates for the three checkpoints of a feature cycle: after planning
  (--plan gates the plan for unstated assumptions and unverifiable success criteria),
  after development (--dev reviews the diff for overcomplication and non-surgical
  changes), and after merge or release (--release captures lessons into rules and
  keeps the agent memory file lean via progressive disclosure). Agent-agnostic:
  targets CLAUDE.md, AGENTS.md, GEMINI.md, or Copilot instructions — Claude Code,
  Codex, Cursor, Copilot, Gemini CLI, Antigravity. --release also bootstraps a new
  repo: creates the memory file if missing, prunes init-generated bloat. Use for
  "review my plan", "gate this diff", "is this overcomplicated", "post-merge hygiene",
  "capture lessons", "CLAUDE.md is too long", "AGENTS.md is too long",
  "set up CLAUDE.md for this repo". Scope with --plan, --dev, --release.
argument-hint: "[--plan|--dev|--release] [--base <ref>]"
---

# phase-gate

One skill, three gates, run at the boundary each gate is named after. `--plan` and
`--dev` are read-only reviews; `--release` writes. Reference paths below are
relative to this skill's directory (Claude Code exposes it as
`${CLAUDE_SKILL_DIR}`); the working directory is the user's project.

| Flag | Gate | When to run | Writes |
|---|---|---|---|
| `--plan` | plan review | after planning, before any code | no |
| `--dev` | diff review | after coding, before push/PR | no |
| `--release` | hygiene pass | after merge or release | yes |

No flag: infer the gate. An uncommitted or unpushed diff → `--dev`. No diff but a
plan in the conversation → `--plan`. Clean tree on the default branch → `--release`.
Say which gate you picked and why before running it.

Gates do not chain. Each runs at a different moment in the cycle, so there is no
`--full`; run the one that matches where the work is.

## Gate 1 — plan review (`--plan`)

Read `references/plan-gate.md` and check the plan in context against it:
assumptions stated, interpretations surfaced, simpler path considered, every
step traceable to the request and paired with a runnable verification.

Verdict is **Ready to build** or **Needs answers**, with the blocking questions
listed. Do not start implementing — the gate ends when the verdict is delivered.

## Gate 2 — diff review (`--dev`)

Read `references/diff-review.md`. Establish the diff first (unstaged + staged;
else the branch against `--base`, default: the repo's default branch), then
review every hunk through the three lenses: Simplicity, Surgical, Verification.

Report per finding:

```
File: src/foo.ts:12-40
Lens: Simplicity | Surgical | Verification
Guideline: <the rule it breaks>
Why: <one sentence>
Suggested action: <minimal change>
```

Close with a table — `# | Finding | Lens | Blocks push?` — and a verdict:
**Ship** or **Trim first**. Report only; fixing the diff is a separate request.

## Gate 3 — hygiene pass (`--release`)

Read `references/memory-hygiene.md`. It targets the repo's agent memory file —
`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, or Copilot instructions, whichever the
repo uses (detection table in the reference). Two jobs, in order:

1. **Capture lessons.** Recurring findings from this cycle's `--dev` reviews (or
   corrections the user made during the work) become rules in the agent's rules
   location, each ≤10 lines, deduped against what is already there.
2. **Keep the memory file lean.** Line-count triage — under 50 ideal, 50–100
   acceptable, over 100 refactor into rules files per the reference. Always
   confirm a `## Verification` section exists, and that the coding guardrails
   (think-before-coding, simplicity, surgical, goal-driven) are linked so they
   stay always-on.

This gate is built to no-op fast: within thresholds, nothing new to capture,
verification section present → report "no action needed" and stop. That is what
makes running it every cycle affordable.

It also doubles as the day-zero bootstrap: no memory file → create one from the
reference's target shape; run once after your agent's init command (Claude
Code's `/init` and equivalents), it prunes the generated file's inferable
content and seeds the guardrails from the start.

**Edit the working tree and stop** — no `git add`, no `git commit`. Review and
commit belong to the user.

## Sources

The plan and diff gates adapt [karpathy-guidelines](https://github.com/forrestchang/andrej-karpathy-skills)
(MIT), derived from [Andrej Karpathy's observations](https://x.com/karpathy/status/2015883857489522876)
on LLM coding pitfalls. The hygiene gate adapts the `reclaude` progressive-disclosure
refactoring skill. The preventive halves of those guidelines belong in the project's
agent memory file; this skill checks compliance at the boundaries, it does not
replace them.
