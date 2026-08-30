# Gate 1 — plan review checklist

Run against the plan the discovery procedure below resolves — a file under
`docs/plans/`, a plan-mode plan, or a written proposal. The gate exists because
assumptions are cheapest to fix before any code exists — every unstated
assumption that survives this gate becomes a `--dev` finding or a rewrite later.

## Finding the plan

The plan is often a file, not a conversation turn. In priority order:

1. **An explicit path** passed to the skill.
2. **A plan file this conversation wrote or referenced** — take the path and
   re-read the file.
3. **The repo's convention** — `docs/plans/`, `docs/superpowers/plans/`,
   `specs/`, or wherever the memory file says plans live. Newest file matching
   the work in hand; if several match, ask which.
4. **A plan in the conversation** — a plan-mode plan or written proposal. Last
   resort, not first.
5. **Nothing found** → say so and stop. There is nothing to gate.

Two rules outrank that ordering:

- **A file beats the conversation's copy of it.** Always re-read from disk. If
  context holds only a summary, that is the strongest reason to go to the file:
  summaries smooth over exactly the hedges and half-decisions this gate looks
  for, so gating one produces a confident false pass.
- **Name the artifact you gated, with its path,** in the output. A gate pointed
  at the wrong thing should be visible in one line.

## Checks

**Assumptions surfaced.** Every assumption the plan rests on is stated
explicitly. Read the plan asking "what would have to be true for this step to
work?" — anything unwritten is a finding. Uncertain assumptions become
questions for the user, not silent picks.

**Interpretations presented.** If the original request admits more than one
reading, the plan names the readings and says which it chose and why. A plan
that silently picked one interpretation of an ambiguous request fails this
check even if the pick is reasonable.

**Simpler path considered.** The plan either is the simplest approach that
solves the problem, or names the simpler alternative and why it was rejected.
"We might need it later" is not a reason; flag it.

**Scope traces to the request.** Every planned step maps to something the user
asked for. Flag speculative items: unrequested configurability, abstractions
for single-use code, error handling for scenarios that cannot occur, features
beyond the ask.

**Success criteria are runnable.** Each step pairs with a verification that can
actually be executed or observed:

```
1. [Step] → verify: [command or observable check]
```

- "Add validation" → "tests for invalid inputs exist and pass"
- "Fix the bug" → "a test reproducing it exists and passes"
- "Refactor X" → "tests pass before and after"

"Make it work" and "verify it looks right" are weak criteria — flag them and
propose a runnable replacement. Strong criteria are what let the implementation
loop run without constant clarification.

## Output

Per-step table:

```
Step | Traceable to request? | Verifiable? | Notes
```

Then the findings (unstated assumptions, silent interpretation picks,
speculative scope, weak criteria), then the verdict:

- **Ready to build** — no blocking findings.
- **Needs answers** — list the blocking questions, one line each, in the order
  they block.

Deliver the verdict and stop. Implementing is the next phase, not this gate.

Who runs this gate: [reviewer-separation.md](reviewer-separation.md).
