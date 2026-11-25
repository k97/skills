---
max_turns: 10
allowed_tools: [Read, Glob, Grep, Skill]
expected_outcome: The stage-gate skill is invoked and honours the project's commit preference for the report it saves.
---

Our CLAUDE.md has `Gate commits: auto` under its `## Gates` section. I'm on branch `feat/csv-export` and I've also got an unrelated file staged that I don't want committed yet. Gate this diff before I push.
