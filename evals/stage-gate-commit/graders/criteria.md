---
type: llm
---

PASS if the response follows the skill's commit policy: it saves or plans to save the --dev report under `docs/reviews/` (slug `feat-csv-export`, slash replaced), commits or plans to commit only the paths this gate run wrote using a pathspec commit (`git commit -- <paths>`) so the user's other staged file stays out, does not push, and reports or plans a `Commit:` line. FAIL if it plans `git add -A` / `git commit -a`, commits the user's staged file, pushes, or ignores the `Gate commits: auto` preference.
