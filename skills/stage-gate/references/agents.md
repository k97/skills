# Agent capability contract

This skill needs six things from its host. Claude Code is the reference implementation — the fullest column, not a special case. Where an agent provides less, degrade explicitly and say so in the report. Never assume a capability and fail silently.

## The matrix

| Capability | Claude Code | `AGENTS.md` agents | Gemini CLI | GitHub Copilot |
| --- | --- | --- | --- | --- |
| Auto-loaded memory file | `CLAUDE.md` | `AGENTS.md`; in monorepos the nearest one to the edited file wins | `GEMINI.md`; also reads `AGENTS.md` when `context.fileName` in `settings.json` lists it, but `GEMINI.md` wins if both exist | `.github/copilot-instructions.md`; also reads `AGENTS.md`, at lower priority |
| On-demand rules location | `.claude/rules/` | files linked from the memory file (e.g. `.agents/rules/`) | files imported into the memory file with `@file.md` | `.github/instructions/*.instructions.md` — **each needs `applyTo:` frontmatter with a glob, or it is ignored** |
| Fresh reviewer | subagent dispatch | subagent or task dispatch where available | varies | generally none |
| Invocation | `/stage-gate --plan` | prose, or the host's own skill syntax | prose | prose |
| Init command | `/init` | varies | varies | none |
| Argument passing | `argument-hint` frontmatter | positional or prose | prose | prose |

`AGENTS.md` is the broadly adopted cross-tool format, not a two-or-three-tool niche. Treat it as the default for any agent not otherwise named here.

Rows 1 and 2 are what Gate 3 writes to. Row 3 is what Gates 1 and 2 need — see [reviewer-separation.md](reviewer-separation.md). Rows 4–6 are how a human reaches the skill at all.

**Copilot's rules location has a trap.** A file written to `.github/instructions/` without `applyTo:` frontmatter is silently ignored — no error, no effect. When Gate 3 splits rules out there, every file it creates must carry a glob, e.g. `applyTo: "**"` for a rule that always applies.

## Detect, do not assume

The table names the agents this skill has been written against. It is not a closed set, and it is not an allowlist. For any agent not listed — and whenever the table and reality disagree — **detection wins**:

- **Memory file.** Use whichever of the four exists in the repo. Only one? Use it. Several? Prefer the running agent's native file. A canonical file with symlinks pointing at it (`CLAUDE.md → AGENTS.md`) is common in multi-agent repos: always edit the canonical file, never the symlink, and never fork the content into two diverging copies.
- **Rules location.** Wherever the memory file already links its split-out rules. If it links none yet, create the directory this table gives for the memory file you detected.
- **Fresh reviewer.** Attempt dispatch. If it is unavailable or fails, take the cold-re-read fallback in [reviewer-separation.md](reviewer-separation.md) and label the report `author-run review, no independent reviewer`.
- **Invocation and arguments.** Never require flag syntax. Every gate must be reachable from plain language; the flags are a shortcut where the host supports them, not the interface.

An agent missing from the table should degrade, not break.

## Verified vs designed-for

Claude Code is the only column exercised end to end.

The other three were checked against each vendor's own documentation, which confirms the file names and locations. Documentation agreement is not a runtime test: read those columns as _designed-for_, not proven. Untested support is a claim, not a feature.

When a row turns out to be wrong, fix the row. Do not add a special case somewhere else — the whole point of this file is that there is one place to look.
