# k97/skills

Multi-skill collection built on the [Agent Skills](https://agentskills.io) standard: `phase-gate`, `codebase-seo`, `apple-appicon`.

## Commands

- `npx skills add k97/skills --skill <name>` — install one skill (takes the repo path, not the skill name)
- Registry visibility: only `SKILL.md` at root, `skills/<name>/SKILL.md`, or `skills/<category>/<name>/SKILL.md` is walked by the CLI

## Rules

- [Coding guardrails](.claude/rules/coding-guardrails.md) — think before coding, simplicity first, surgical changes, goal-driven execution

## Verification

- `/validate-skills` — check every `skills/<name>/SKILL.md` against the agentskills.io spec and Claude Code best practices
- `npx skills add k97/skills --list` — confirm the registry CLI sees each published skill
- `bash -n skills/*/scripts/*.sh` — syntax-check the shell scripts
