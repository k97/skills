---
name: stage-gate
description: >-
  Quality gates for the three boundaries of a feature cycle, run by a fresh reviewer rather than the author. --plan gates a written plan — in the conversation or a file under docs/plans or specs — for unstated assumptions, ambiguity, and unverifiable success criteria. --dev reviews the diff for overcomplication and non-surgical changes. --release captures lessons into rules and keeps the agent memory file lean. --dev and --release may run in sequence. Use when the user says "review my plan", "check the plan before we build", "any assumptions I missed", "gate this diff", "review before I push", "is this overcomplicated", "did I touch more than I needed", "verify and release", "wrap up this feature", "capture lessons", "CLAUDE.md is too long", or "set up CLAUDE.md for this repo". Agent-agnostic: CLAUDE.md, AGENTS.md, GEMINI.md, or Copilot instructions. --release also bootstraps a new repo.
license: MIT
metadata:
  version: "0.3.0"
  source: https://github.com/k97/skills/tree/main/skills/stage-gate
---

# Quality gates for a feature cycle

Reviews your work at the three points where problems are cheapest to catch: the plan before code is written, the diff before it is pushed, and the repo after the merge. Each gate is run by a fresh reviewer rather than the author, and the release gate turns what was learned into rules while keeping CLAUDE.md or AGENTS.md short. Reviews are saved under `docs/reviews/`, and a one-line project preference (`Gate commits: auto`) has each gate commit the files it wrote, so you don't have to ask.

| Gate | Run it when | It checks | Writes |
| --- | --- | --- | --- |
| `--plan` | a plan exists, no code written yet | assumptions, ambiguity, simpler paths, runnable success criteria | its report (and the preference line, once) |
| `--dev` | code is written, not yet pushed | every hunk traces to the request | its report (and the preference line, once) |
| `--release` | the branch is merged or released | lessons captured, memory file lean and armed | memory file and rules |

Run each gate at its boundary **even when the work looks finished**. That is the moment the gate is for, and the moment it is easiest to skip.

## Picking a gate

An explicit flag wins. With no flag, infer from state — then say which gate you picked and why before running it:

- uncommitted or unpushed diff → `--dev`
- no diff, but a plan in the conversation or a recent plan file → `--plan`
- clean tree on the default branch → `--release`

Changes confined to `docs/reviews/`, whether uncommitted or in unpushed commits, are the gates' own reports. They don't count as a diff.

Gates may be requested together when a request spans two boundaries — "verify and release" is `--dev` then `--release`. Run them in cycle order, each with its own artifact, reviewer, and verdict; never merge the reports, and let a blocking `--dev` stop the sequence. There is no `--full`: `--plan` never co-occurs with the others, since by the time there is a diff it has passed or been skipped.

Reference paths below resolve against this skill's own directory; the working directory is the user's project.

## Gate 1 — plan review (`--plan`)

**After planning, before any code.** Read [references/plan-gate.md](references/plan-gate.md) — it carries the procedure for locating the plan, which is often a file rather than a conversation turn, and the checks to run against it. Send it to a fresh reviewer, not yourself: [references/reviewer-separation.md](references/reviewer-separation.md).

Verdict is **Ready to build** or **Needs answers**, blocking questions listed. Do not start implementing — the gate ends when the verdict is delivered.

## Gate 2 — diff review (`--dev`)

**After coding, before push or PR.** Read [references/diff-review.md](references/diff-review.md) — it carries the procedure for establishing the diff, the three lenses (Simplicity, Surgical, Verification), and the report format. Dispatch to a fresh reviewer per [references/reviewer-separation.md](references/reviewer-separation.md); an author reviewing their own diff has every justification still loaded.

Verdict is **Ship** or **Trim first**. This gate reports and saves its report; fixing the diff is a separate request.

## Gate 3 — hygiene pass (`--release`)

**After merge or release.** The only gate that edits the project beyond reports and the one-time preference line. Read [references/memory-hygiene.md](references/memory-hygiene.md), which resolves the repo's memory file and rules location from [references/agents.md](references/agents.md). Two jobs, in order:

1. **Capture lessons** from this cycle as rules in the agent's rules location.
2. **Keep the memory file lean and armed** — line-count triage, plus a `## Verification` section, the coding guardrails, and the gate-trigger block. That block is what makes these gates fire from workflow state instead of waiting to be remembered, so it must sit in the memory file itself.

The reference carries the thresholds, the fast no-op check that makes this affordable every cycle, and the day-zero bootstrap for a repo with no memory file yet.

Edit the working tree, then stop or commit per the next section.

## Saving and committing

Before any gate writes, read [references/gate-output.md](references/gate-output.md). It covers where reports are saved, the `Gate commits:` preference (ask once when it's unset), and whether and how to commit.

## Sources

[references/sources.md](references/sources.md) — provenance, MIT attribution, and why these gates do not replace always-on rules.
