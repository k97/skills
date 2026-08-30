# Gate 3 — hygiene pass

Runs after merge or release. Two jobs in order: capture what the cycle taught,
then keep the agent memory file lean enough that what it says still gets read.
This is the only gate that writes — working tree only, never commit.

## Find the memory file

This gate is agent-agnostic: it targets whichever memory file the repo uses.
"CLAUDE.md" elsewhere in this skill means "the memory file" in the general case.

| Agent | Memory file | Rules / split-out location |
|---|---|---|
| Claude Code | `CLAUDE.md` | `.claude/rules/` |
| Codex, Cursor, Antigravity, most others | `AGENTS.md` | files linked from it (e.g. `.agents/rules/`) |
| Gemini CLI | `GEMINI.md` (reads `AGENTS.md` if configured) | files linked from it |
| GitHub Copilot | `.github/copilot-instructions.md` | `.github/instructions/*.instructions.md` |

Detection: prefer the running agent's native file; if only one memory file
exists, use it. Multi-agent repos often keep a canonical `AGENTS.md` with
symlinks (`CLAUDE.md → AGENTS.md`) — always edit the canonical file, never a
symlink, and never fork the content into two diverging copies. The thresholds,
jobs, and refactor steps below apply identically whichever file it is; write
split-out rules to that agent's rules location from the table.

## Fast no-op check

Run this triage first so the gate stays cheap enough for every cycle:

- memory file ≤100 lines,
- a `## Verification` section exists,
- the coding guardrails are present or linked (see below),
- the gate-trigger block is in the memory file (see below),
- nothing new to capture from this cycle.

All five true → report "no action needed" with the line count, and stop.

**No memory file at all?** Not a no-op — create the running agent's native file
from the target shape below: discover the Verification commands, seed the
guardrails rule, and stop there (nothing to group, nothing to delete). This
makes `--release` the day-zero bootstrap for a new repo. Run it once right
after your agent's init command (Claude Code's `/init` and equivalents), too —
auto-generated memory files are full of exactly the content the deletion list
prunes.

## Job 1 — capture lessons

Sources, in order of signal strength:

1. Findings that recurred across this cycle's `--dev` reviews.
2. Corrections the user made during the work ("no, we always…", "stop doing…").
3. Non-obvious discoveries — gotchas, footguns, things that cost real time.

For each: distill to a rule of ≤10 lines in the agent's rules location — the
behavior, one line of why, nothing else. Dedupe against existing rules; extend
an existing file over creating a near-duplicate. Skip anything the agent can
infer from the codebase, and anything that only mattered this once.

If a lesson is about a tool or framework rather than this project, and would
apply in 2+ projects, suggest a global skill (`~/.claude/skills/`,
`~/.agents/skills/`, or your agent's equivalent) with a name and description
instead of a project rule.

## Job 2 — memory file triage

| Line count | Action |
|---|---|
| <50 | ideal — verify guardrails + verification section, done |
| 50–100 | acceptable — trim opportunistically, no restructure |
| >100 | refactor into the rules location per the steps below |

**Always, regardless of length:**

- `## Verification` section exists with runnable commands. If missing, discover
  them (package.json scripts, Makefile, justfile) and add it. Agents perform
  dramatically better when they can verify their work.
- The coding guardrails are always-on: a section or linked
  `coding-guardrails.md` rule covering think-before-coding, simplicity first,
  surgical changes, and goal-driven execution. If absent, create the rules file
  with those four guidelines and link it. This is the preventive half of Gates
  1 and 2 — without it the guidelines only exist at review time, after the
  mistakes are already made.
- The gate-trigger block is present, verbatim from the section below. Without
  it the gates only run when someone remembers to ask for them — and the three
  boundaries are exactly where nobody does, since each one arrives the moment
  the work is declared finished.

### The gate-trigger block

Four lines, in the memory file itself:

```markdown
## Gates

Run the `stage-gate` skill at each boundary, even when the work looks finished
— dispatch a fresh reviewer, do not gate your own work:
plan written → `--plan`, code written before push → `--dev`, merged → `--release`.
```

This block cannot be split out into a rules file. Linked rules are read on
demand; only the memory file is loaded every session, and a trigger that has to
be looked up first is not a trigger. It is the one exception to the "move it to
the rules location" instinct — four lines is the price of the gates firing at
all. If the project installed this skill under a different name, use that name.

## Refactor steps (only when >100 lines)

1. **Find contradictions.** Conflicting instructions → ask the user which wins.
   This is the one step that may need input; everything else proceeds.
2. **Extract root essentials.** What stays in the memory file: one-line project
   description, package manager if not npm, non-obvious commands only, links to
   rules files with one-line descriptions, the Verification section.
3. **Group the rest** into the rules location by topic (conventions, testing,
   architecture, git workflow).
4. **Delete outright:** API docs (link instead), code examples (the source is
   the example), type definitions (they live in the code), generic advice
   ("write clean code"), anything the agent infers from reading the repo.

### Target shape

```markdown
# Project Name

One-line description.

## Commands
- `command` — what it does (non-obvious only)

## Rules
- [Topic](<rules-location>/topic.md) — one line

## Gates
Run the `stage-gate` skill at each boundary, even when the work looks finished
— dispatch a fresh reviewer, do not gate your own work:
plan written → `--plan`, code written before push → `--dev`, merged → `--release`.

## Verification
- `npm test` — run tests
- `npm run lint` — check linting
```

## Output

Report: which memory file was targeted, lessons captured (file + one-line
summary each), before/after line count, what moved where, what was deleted and
why, whether the gate-trigger block was already present or added, and any
contradiction awaiting the user's call. Then stop — no `git add`,
no `git commit`.
