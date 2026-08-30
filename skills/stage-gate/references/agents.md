# Agent capability contract

This skill needs six things from its host. Claude Code is the reference
implementation — the fullest column, not a special case. Where an agent
provides less, degrade explicitly and say so in the report. Never assume a
capability and fail silently.

## The matrix

| Capability | Claude Code | Codex · Cursor · Antigravity | Gemini CLI | GitHub Copilot |
|---|---|---|---|---|
| Auto-loaded memory file | `CLAUDE.md` | `AGENTS.md` | `GEMINI.md` (reads `AGENTS.md` if configured) | `.github/copilot-instructions.md` |
| On-demand rules location | `.claude/rules/` | files linked from the memory file (e.g. `.agents/rules/`) | files linked from the memory file | `.github/instructions/*.instructions.md` |
| Fresh reviewer | subagent dispatch | subagent or task dispatch where available | varies | generally none |
| Invocation | `/stage-gate --plan` | prose, or the host's own skill syntax | prose | prose |
| Init command | `/init` | varies | varies | none |
| Argument passing | `argument-hint` frontmatter | positional or prose | prose | prose |

Rows 1 and 2 are what Gate 3 writes to. Row 3 is what Gates 1 and 2 need — see
[reviewer-separation.md](reviewer-separation.md). Rows 4–6 are how a human
reaches the skill at all.

## Detect, do not assume

The table names the agents this skill has been written against. It is not a
closed set, and it is not an allowlist. For any agent not listed — and whenever
the table and reality disagree — **detection wins**:

- **Memory file.** Use whichever of the four exists in the repo. Only one? Use
  it. Several? Prefer the running agent's native file. A canonical file with
  symlinks pointing at it (`CLAUDE.md → AGENTS.md`) is common in multi-agent
  repos: always edit the canonical file, never the symlink, and never fork the
  content into two diverging copies.
- **Rules location.** Wherever the memory file already links its split-out
  rules. If it links none yet, create the directory this table gives for the
  memory file you detected.
- **Fresh reviewer.** Attempt dispatch. If it is unavailable or fails, take the
  cold-re-read fallback in [reviewer-separation.md](reviewer-separation.md) and
  label the report `author-run review, no independent reviewer`.
- **Invocation and arguments.** Never require flag syntax. Every gate must be
  reachable from plain language; the flags are a shortcut where the host
  supports them, not the interface.

An agent missing from the table should degrade, not break.

## Verified vs designed-for

Claude Code is the only column exercised end to end. The others are written
from each agent's documented behaviour and should be read as *designed-for*,
not proven. Untested support is a claim, not a feature.

When a row turns out to be wrong, fix the row. Do not add a special case
somewhere else — the whole point of this file is that there is one place to
look.
