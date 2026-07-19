# Gate 1 — plan review checklist

Run against the plan in context (a plan-mode plan, a written proposal, or the
user's own outline). The gate exists because assumptions are cheapest to fix
before any code exists — every unstated assumption that survives this gate
becomes a `--dev` finding or a rewrite later.

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
