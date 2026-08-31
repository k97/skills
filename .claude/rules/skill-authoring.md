# Skill authoring

Rules specific to writing skills in this repo. Token economy is a design constraint here, not a nicety.

- **`SKILL.md` is charged on every invocation; `references/` is not.** Keep the body to routing, verdicts, and invariants that hold regardless of gate. Move procedures, checklists, thresholds and report formats into a reference — the agent reads it before running that gate anyway.
- **One fact, one file.** Never copy a table or rule into two skill files. A duplicated table drifts, and drift in a skill is silent — nothing fails, the agent just follows the stale copy.
- **Anything the agent must act on without being asked has to be in the memory file itself.** Linked rules are read on demand, so a trigger placed in `.claude/rules/` is not a trigger.
- **State what the host must provide, then degrade explicitly.** Where a skill needs a capability not every agent has, name the fallback and make the report say which path ran. Untested support is a claim, not a feature — label it.
