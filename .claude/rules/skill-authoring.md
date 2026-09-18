# Skill authoring

Rules specific to writing skills in this repo. Token economy is a design constraint here, not a nicety.

- **`SKILL.md` is charged on every invocation; `references/` is not.** Keep the body to routing, verdicts, and invariants that hold regardless of gate. Move procedures, checklists, thresholds and report formats into a reference — the agent reads it before running that gate anyway.
- **The body opens with a summary a human can read.** skills.sh renders the SKILL.md body from its H1 and shows the frontmatter nowhere, so the first paragraph under the H1 is a short plain-English account of what the skill does and for whom. The frontmatter `description` stays the agent-facing trigger text; do not repeat the summary in the sentence that follows it.
- **One fact, one file.** Never copy a table or rule into two skill files. A duplicated table drifts, and drift in a skill is silent — nothing fails, the agent just follows the stale copy.
- **Anything the agent must act on without being asked has to be in the memory file itself.** Linked rules are read on demand, so a trigger placed in `.claude/rules/` is not a trigger.
- **State what the host must provide, then degrade explicitly.** Where a skill needs a capability not every agent has, name the fallback and make the report say which path ran. Untested support is a claim, not a feature — label it.
- **Run it before you ship it.** Every command, flag, template and tool name a skill carries is executed on the target platform before publish, and every vendor claim names its source; what could not be verified is labelled in the skill, not left implied. The macos-app-performance review found an erroring flag, a removed Instruments template and a permissions invariant the machine contradicted — none of them fail loudly, the agent just follows them.
- **Name against what is already installed.** Before naming a skill, check the registry and `~/.claude/skills` for the same name; a collision with a broader skill hijacks its triggers. `macos-perf` collided with a whole-machine skill and had to be renamed after publish.
- **README restates skill claims, so a fix lands in both.** When a fact in a skill changes, grep README.md for the old wording; the README kept "Thread State Trace" after the skill had dropped it.
