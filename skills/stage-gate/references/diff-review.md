# Gate 2 — diff review lenses

Review the diff, not the codebase. Pre-existing problems outside the changed
lines are out of scope (mention at most, never a finding). The single test
behind all three lenses: **every changed line should trace directly to the
user's request.**

## Establishing the diff

1. `git status` + `git diff` + `git diff --staged` — if there is uncommitted
   work, that is the diff.
2. Otherwise the branch: `git diff <base>...HEAD` where `<base>` is the
   `--base` argument, else the repo's default branch (`git remote show origin`
   or the obvious `main`/`master`).
3. No diff anywhere → say so and stop; there is nothing to gate.

Read every hunk. A stat summary is not a review.

## Lens 1 — Simplicity

Minimum code that solves the problem; nothing speculative.

- Features beyond what was asked.
- Abstractions serving a single call site.
- "Flexibility" or "configurability" nobody requested — options, params,
  indirection with one live value.
- Error handling for scenarios that cannot occur.
- Line count: if 200 lines could be 50, that is a finding even when the code
  works. The question to ask: "would a senior engineer call this
  overcomplicated?"

## Lens 2 — Surgical

Touch only what the request requires; clean up only your own mess.

- Hunks with no connection to the request: reformatting, comment "improvements",
  refactors of adjacent working code, style changes to lines that did not need
  to change.
- Style drift: new code that fights the file's existing idiom.
- Orphans **created by this diff** — imports, variables, functions the change
  made unused but left behind. These are findings.
- Pre-existing dead code **deleted** by this diff without being asked — also a
  finding (the surgical rule cuts both ways: mention dead code, don't remove it).

## Lens 3 — Verification

The work is done when verified, not when written.

- Were the repo's checks run — tests, lint, typecheck, build? Check the
  `## Verification` section of the repo's agent memory file (CLAUDE.md,
  AGENTS.md, GEMINI.md, or Copilot instructions) for the canonical list; run
  them if cheap, and report any that were skipped and why.
- If Gate 1 produced success criteria, walk them: each one met, with evidence?
- New behavior with no test exercising it is a finding when the repo has a test
  suite the change plausibly belongs in.

## Output

Per finding:

```
File: src/foo.ts:12-40
Lens: Simplicity | Surgical | Verification
Guideline: <the rule it breaks>
Why: <one sentence>
Suggested action: <minimal change>
```

Close with `# | Finding | Lens | Blocks push?` and a verdict: **Ship** (no
blocking findings) or **Trim first** (blocking findings listed in order).

This gate reports; it does not edit. Findings that keep recurring across cycles
are exactly what Gate 3 distills into the agent's rules location — note repeat
offenders so the hygiene pass can pick them up.
