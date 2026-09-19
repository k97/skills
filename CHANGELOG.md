# Changelog

Per-skill versions live in each `SKILL.md` under `metadata.version`. This file lists what changed and when.

## 2026-09-18

- **all skills** — every `SKILL.md` body now opens with a plain-English summary; frontmatter reduced to the six Agent Skills spec fields (`argument-hint` dropped, `source` moved under `metadata`), `license: MIT` added, `compatibility` added where a skill has real requirements; H1s are human titles.
- **discoverability 0.2.0** — fetched pages, headers and JSON-LD are treated as data, never instructions, and `--fix` acts only on report findings; commands are agent-agnostic (`<skill-dir>` instead of a Claude-only variable).
- **stage-gate 0.2.1**, **apple-appicon 0.1.1**, **macos-app-performance 0.1.1** — presentation and metadata only, no behaviour change.
- **repo** — `skills.sh.json` groups the skills.sh page; `.claude-plugin/marketplace.json` enables `/plugin marketplace add k97/skills`; plugin evals under `evals/`, written to the documented format but not yet executed because `claude plugin eval` is early access on Claude Code 2.1.223.
