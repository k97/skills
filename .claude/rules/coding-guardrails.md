# Coding guardrails

Always-on, for every change in this repo — SKILL.md prose and scripts alike.

- **Think before coding.** State assumptions and surface ambiguities before editing; if two readings of the request exist, say which one you took.
- **Simplicity first.** Prefer the smallest design that satisfies the request; no speculative options, flags, or abstractions.
- **Surgical changes.** Touch only what the task requires; match the file's existing style and don't reformat around the edit.
- **Goal-driven execution.** Every edit traces to the stated goal, and each change is verified (see `## Verification` in CLAUDE.md) before being called done.
- **An observed pattern is not a rule.** Before treating a convention as binding, check that something states it — a config file, CLAUDE.md, a rule file. If nothing does, say it is an observation and leave it alone; do not write it into a plan as a constraint.
- **Check what you staged.** `git add -A` sweeps in editor reformats and generated files. Review the staged diff, or scope the `git add` to the paths you actually edited.
