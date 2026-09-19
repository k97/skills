# k97/skills

Multi-skill collection built on the [Agent Skills](https://agentskills.io) standard: `stage-gate`, `apple-appicon`, `discoverability`, `macos-app-performance`.

## Commands

- `npx skills add k97/skills --skill <name>` — install one skill (takes the repo path, not the skill name)
- `/plugin marketplace add k97/skills` — Claude Code plugin path; `.claude-plugin/marketplace.json` lists the skills
- Registry visibility: only `SKILL.md` at root, `skills/<name>/SKILL.md`, or `skills/<category>/<name>/SKILL.md` is walked by the CLI

## Rules

- [Coding guardrails](.claude/rules/coding-guardrails.md) — think before coding, simplicity first, surgical changes, goal-driven execution
- [Skill authoring](.claude/rules/skill-authoring.md) — SKILL.md is charged every invocation, references are not; one fact one file; run every command before publishing

## Gates

Run the `stage-gate` skill at each boundary, even when the work looks finished — dispatch a fresh reviewer, do not gate your own work: plan written → `--plan`, code written before push → `--dev`, merged → `--release`.

## Verification

- `/validate-skills` — check every `skills/<name>/SKILL.md` against the agentskills.io spec and Claude Code best practices
- `npx skills add k97/skills --list` — confirm the registry CLI sees each published skill (run it against the pushed repo path; `.` also walks the `.claude/skills` symlink, so it is not a local check)
- `bash -n skills/*/scripts/*.sh` — syntax-check the shell scripts
- `npx -y skills-ref validate skills/<name>` — spec validator; fails on any frontmatter key outside the six spec fields
- `claude plugin validate .` — validates `.claude-plugin/marketplace.json` structure only; it does not check that listed skill paths exist
