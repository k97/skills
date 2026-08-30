---
name: stage-gate
description: >-
  Quality gates for the three boundaries of a feature cycle. Run --plan once a plan
  exists and no code is written yet (gates it for unstated assumptions, ambiguity,
  unverifiable success criteria); --dev once code is written but not pushed (reviews
  the diff for overcomplication and non-surgical changes); --release once a branch is
  merged or released (captures lessons into rules, keeps the agent memory file lean,
  installs the always-on gate triggers). Run each gate at its boundary even when the
  work looks finished. Agent-agnostic: targets CLAUDE.md, AGENTS.md, GEMINI.md, or
  Copilot instructions — Claude Code, Codex, Cursor, Copilot, Gemini CLI, Antigravity.
  --release also bootstraps a new repo: creates the memory file if missing, prunes
  init-generated bloat. Use for "review my plan", "gate this diff", "is this
  overcomplicated", "post-merge hygiene", "capture lessons", "CLAUDE.md is too long",
  "AGENTS.md is too long", "set up CLAUDE.md for this repo".
argument-hint: "[--plan|--dev|--release] [<plan-path>] [--base <ref>]"
---

# stage-gate

Three quality gates, one at each boundary of a feature cycle.

| Gate | Run it when | It checks | Writes |
|---|---|---|---|
| `--plan` | a plan exists, no code written yet | assumptions, ambiguity, simpler paths, runnable success criteria | no |
| `--dev` | code is written, not yet pushed | every hunk traces to the request | no |
| `--release` | the branch is merged or released | lessons captured, memory file lean and armed | yes |

Run each gate at its boundary **even when the work looks finished**. That is the
moment the gate is for, and the moment it is easiest to skip.

## Picking a gate

An explicit flag wins. With no flag, infer from state — then say which gate you
picked and why before running it:

- uncommitted or unpushed diff → `--dev`
- no diff, but a plan in the conversation or a recent plan file → `--plan`
- clean tree on the default branch → `--release`

Gates may be requested together when one request spans two boundaries —
"verify and release" is `--dev` then `--release`. Run them in cycle order, each
as its own gate with its own artifact, reviewer, and verdict; never merge the
reports. A blocking `--dev` verdict stops the sequence: report it, fix first,
release after. There is still no `--full`, because `--plan` never co-occurs
with the others — by the time there is a diff, the plan gate has passed or been
skipped.

Reference paths below resolve against this skill's own directory; the working
directory is the user's project.

## Gate 1 — plan review (`--plan`)

**After planning, before any code.**

Read [references/plan-gate.md](references/plan-gate.md), locate the plan by the
discovery procedure it carries — it is often a file, not a conversation turn —
then check it: assumptions stated, interpretations surfaced, simpler path
considered, every step traceable to the request and paired with a runnable
verification.

Run it through a fresh reviewer, not yourself — see
[references/reviewer-separation.md](references/reviewer-separation.md).

Verdict is **Ready to build** or **Needs answers**, with the blocking questions
listed. Do not start implementing — the gate ends when the verdict is delivered.

## Gate 2 — diff review (`--dev`)

**After coding, before push or PR.**

Read [references/diff-review.md](references/diff-review.md). Establish the diff
first (unstaged + staged; else the branch against `--base`, default: the repo's
default branch), then review every hunk through the three lenses — Simplicity,
Surgical, Verification. The reference carries the per-finding report format.

Dispatch it to a fresh reviewer per
[references/reviewer-separation.md](references/reviewer-separation.md); an
author reviewing their own diff has every justification still loaded.

Verdict is **Ship** or **Trim first**. This gate reports only; fixing the diff
is a separate request.

## Gate 3 — hygiene pass (`--release`)

**After merge or release.** The only gate that writes.

Read [references/memory-hygiene.md](references/memory-hygiene.md). It targets the
repo's agent memory file — `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, or Copilot
instructions, whichever the repo uses (detection table in the reference). Two
jobs, in order:

1. **Capture lessons.** Recurring findings from this cycle's `--dev` reviews, and
   corrections the user made during the work, become rules in the agent's rules
   location — each ≤10 lines, deduped against what is already there.
2. **Keep the memory file lean and armed.** Line-count triage: under 50 ideal,
   50–100 acceptable, over 100 refactor into rules files. Then confirm three
   things are in place — a `## Verification` section, the coding guardrails, and
   the gate-trigger block. The trigger block must sit in the memory file itself:
   linked rules are read on demand, and a trigger that has to be looked up first
   is not a trigger.

Job 2 is what makes the gates fire from workflow state instead of waiting to be
remembered. Without it this skill only ever runs when someone thinks to ask for
it — and the three boundaries are exactly where nobody does, because each one
lands the moment the work is declared done.

This gate is built to no-op fast: within thresholds, nothing new to capture,
always-on block intact → report "no action needed" and stop. That is what makes
running it every cycle affordable.

It also doubles as the day-zero bootstrap: no memory file → create one from the
reference's target shape. Run it once after your agent's init command (Claude
Code's `/init` and equivalents) — it prunes the generated file's inferable
content and seeds the always-on block from the start.

**Edit the working tree and stop** — no `git add`, no `git commit`. Review and
commit belong to the user.

## Sources

[references/sources.md](references/sources.md) — provenance, MIT attribution, and
why these gates do not replace always-on rules.
