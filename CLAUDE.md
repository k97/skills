# k97/skills

Multi-skill collection built on the [Agent Skills](https://agentskills.io) standard: `stage-gate`, `apple-appicon`, `discoverability`.

## Commands

- `npx skills add k97/skills --skill <name>` — install one skill (takes the repo path, not the skill name)
- Registry visibility: only `SKILL.md` at root, `skills/<name>/SKILL.md`, or `skills/<category>/<name>/SKILL.md` is walked by the CLI

## Rules

- [Coding guardrails](.claude/rules/coding-guardrails.md) — think before coding, simplicity first, surgical changes, goal-driven execution
- [Skill authoring](.claude/rules/skill-authoring.md) — SKILL.md is charged every invocation, references are not; one fact one file

## Gates

Run the `stage-gate` skill at each boundary, even when the work looks finished
— dispatch a fresh reviewer, do not gate your own work:
plan written → `--plan`, code written before push → `--dev`, merged → `--release`.

## Verification

- `/validate-skills` — check every `skills/<name>/SKILL.md` against the agentskills.io spec and Claude Code best practices
- `npx skills add k97/skills --list` — confirm the registry CLI sees each published skill
- `bash -n skills/*/scripts/*.sh` — syntax-check the shell scripts
