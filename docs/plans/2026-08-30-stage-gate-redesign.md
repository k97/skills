# stage-gate Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `stage-gate` work in a single continuous conversation where the user says "write a plan" → "implement it" → "verify and release", instead of only when they remember to type a flag at a boundary.

**Architecture:** Four independent changes to prose files. Gate 1 gains an artifact-discovery procedure symmetric to the one Gate 2 already has. Gates 1 and 2 gain reviewer separation via subagent dispatch, with an explicit degraded fallback. The "gates never chain" rule is removed because real requests span boundaries. Trigger surfaces — frontmatter description, README, and the memory-file block — are rewritten around what users actually type.

**Tech Stack:** Markdown only. No code, no build step. Verification is `/validate-skills` plus grep/fence assertions run in bash.

**Spec:** None separate — the requirements were established in conversation on 2026-08-30 and are restated in full under "Problem statement" below. That section is the spec; the plan argues from it.

## Global Constraints

- `SKILL.md` `description` must stay ≤1024 characters (agentskills.io spec).
- `SKILL.md` body must stay under 500 lines; keep it under 130 — it loads on every invocation.
- Every file in `references/` must be linked from `SKILL.md` (one-level-deep rule). Cross-links between references are allowed only as navigation, never as the sole path to a file.
- The skill is **agent-agnostic**. Claude Code, Codex, Cursor, Copilot, Gemini CLI, Antigravity. Any capability not universally available must degrade explicitly, never be assumed.
- No `git add`, no `git commit` inside any gate. Working tree only.
- Match existing prose style: ~80 column wrap, sentence case headings, em dashes.

---

## Problem statement

Four defects, established by tracing the skill against the user's real workflow.

**1. Gate 1 cannot find its artifact.** `plan-gate.md:3` says "Run against the plan in context"; `SKILL.md:38` says "a plan in the conversation". A grep for `docs/`, `specs/`, "plan file", "on disk" across the skill returns nothing — the possibility that a plan is a file does not exist in the skill. Gates 2 and 3 both have real discovery procedures (ordered git commands with a stop condition; a four-agent detection table). Gate 1 got one sentence. The failure is silent: with the plan on disk and out of context, the gate reviews whatever plan-shaped text is nearest in the conversation, which after compaction is a *summary*. Summaries smooth over the hedges and half-decisions the gate exists to catch, so it returns "Ready to build" on a plan it never read.

**2. The gate is run by the author.** No notion of a subagent, fresh context, or independent reviewer appears anywhere in the skill. In a single continuous conversation the agent that wrote the plan is the agent that gates it, with all its justifications still in context. `plan-gate.md` asks whether the plan "silently picked one interpretation" — a question the picker structurally cannot answer, because from the inside the pick felt like the obvious reading.

**3. Gates are forbidden from chaining, but real requests chain them.** `SKILL.md:41-42` states there is deliberately no `--full` because "chaining never matches a real invocation". The user's step 4 is "verify and release" — `--dev` then `--release` in one request. The justification is false.

**4. The trigger surfaces are phrased for a user who already knows the skill.** The description lists phrases like "post-merge hygiene" — vocabulary from the skill, not from someone with a diff in front of them. There is no documented set of prompts that load and leverage it.

---

## File structure

| File | Responsibility | Change |
|---|---|---|
| `skills/stage-gate/SKILL.md` | Routing, gate selection, per-gate summary | Modify — chaining rule, discovery pointer, reviewer pointer, description |
| `skills/stage-gate/references/plan-gate.md` | Gate 1 checklist | Modify — add "Finding the plan" |
| `skills/stage-gate/references/diff-review.md` | Gate 2 lenses | Modify — link reviewer separation |
| `skills/stage-gate/references/reviewer-separation.md` | Shared: who runs a gate | **Create** |
| `skills/stage-gate/references/memory-hygiene.md` | Gate 3 | Modify — trigger block wording |
| `README.md` | Human-facing docs | Modify — indicating prompts section |

`reviewer-separation.md` is a new file rather than SKILL.md prose because it applies to Gates 1 and 2 but not Gate 3 — putting it in the body would charge every `--release` invocation for content it never uses.

---

### Task 1: Give Gate 1 an artifact-discovery procedure

**Files:**
- Modify: `skills/stage-gate/references/plan-gate.md` (insert after line 6, before `## Checks`)
- Modify: `skills/stage-gate/SKILL.md` (`argument-hint`, and the `--plan` inference bullet)

**Interfaces:**
- Produces: the heading `## Finding the plan` in `plan-gate.md`; Task 5's verification greps for it.
- Produces: `argument-hint` accepting an optional plan path; Task 4's README examples rely on it.

- [ ] **Step 1: Insert the discovery section into `plan-gate.md`**

Insert immediately after the opening paragraph (which ends `...becomes a --dev finding or a rewrite later.`) and before `## Checks`:

```markdown
## Finding the plan

The plan is often a file, not a conversation turn. In priority order:

1. **An explicit path** passed to the skill.
2. **A plan file this conversation wrote or referenced** — take the path and
   re-read the file.
3. **The repo's convention** — `docs/plans/`, `docs/superpowers/plans/`,
   `specs/`, or wherever the memory file says plans live. Newest file matching
   the work in hand; if several match, ask which.
4. **A plan in the conversation** — a plan-mode plan or written proposal. Last
   resort, not first.
5. **Nothing found** → say so and stop. There is nothing to gate.

Two rules outrank that ordering:

- **A file beats the conversation's copy of it.** Always re-read from disk. If
  context holds only a summary, that is the strongest reason to go to the file:
  summaries smooth over exactly the hedges and half-decisions this gate looks
  for, so gating one produces a confident false pass.
- **Name the artifact you gated, with its path,** in the output. A gate pointed
  at the wrong thing should be visible in one line.
```

- [ ] **Step 2: Widen `argument-hint` in `SKILL.md`**

Replace:

```yaml
argument-hint: "[--plan|--dev|--release] [--base <ref>]"
```

with:

```yaml
argument-hint: "[--plan|--dev|--release] [<plan-path>] [--base <ref>]"
```

- [ ] **Step 3: Update the `--plan` inference bullet in `SKILL.md`**

Replace:

```markdown
- no diff, but a plan in the conversation → `--plan`
```

with:

```markdown
- no diff, but a plan in the conversation or a recent plan file → `--plan`
```

- [ ] **Step 4: Verify**

```bash
cd /Users/karthik/Work/Projects/rkarthik/skills
grep -q "^## Finding the plan" skills/stage-gate/references/plan-gate.md && echo "PASS section" || echo "FAIL section"
grep -q "plan-path" skills/stage-gate/SKILL.md && echo "PASS arg-hint" || echo "FAIL arg-hint"
grep -c "docs/plans/" skills/stage-gate/references/plan-gate.md   # expect >= 1
grep -n "plan in context" skills/stage-gate/references/plan-gate.md || echo "PASS stale wording gone"
```

Expected: `PASS section`, `PASS arg-hint`, count ≥ 1, `PASS stale wording gone`.

- [ ] **Step 5: Commit**

```
git add skills/stage-gate/references/plan-gate.md skills/stage-gate/SKILL.md
git commit -m "feat(stage-gate): give Gate 1 an artifact-discovery procedure"
```

---

### Task 2: Separate reviewer from author for Gates 1 and 2

**Files:**
- Create: `skills/stage-gate/references/reviewer-separation.md`
- Modify: `skills/stage-gate/SKILL.md` (link it; one line in each of Gate 1 and Gate 2)
- Modify: `skills/stage-gate/references/plan-gate.md`, `references/diff-review.md` (navigational cross-link)

**Interfaces:**
- Consumes: `## Finding the plan` from Task 1 — the subagent brief hands over the artifact *path* that procedure resolved.
- Produces: `references/reviewer-separation.md`, which must be linked from `SKILL.md` or Task 5's one-level-deep check fails.

- [ ] **Step 1: Create `references/reviewer-separation.md`**

```markdown
# Who runs the gate

Gates 1 and 2 audit work. When the agent that produced the work also runs the
gate, the audit is compromised in a specific way: the reasoning behind every
choice is still in context, where it reads as justification rather than as the
thing under review. An agent cannot notice that it picked an interpretation
silently — from the inside, the pick felt like the obvious reading.

So the reviewer must not be the author.

## Preferred — dispatch a subagent

One subagent per gate. Give it exactly:

- the user's original request, verbatim
- the artifact under review: the plan file's contents, or the diff
- the `## Verification` section of the repo's memory file
- this gate's reference file

Do **not** give it your reasoning, your justifications, the conversation
history, or a summary of why the work came out the way it did. Those are what
is being audited — passing them along is precisely what defeats the gate.

Ask for the gate's standard output format. Relay the verdict as it came back.
Do not soften findings about your own work, and do not argue with them in the
same breath as reporting them.

## Fallback — cold re-read

Where subagent dispatch is unavailable, degrade explicitly rather than quietly:

1. Re-read the artifact from disk (or from `git diff`) as the source of truth.
   Never gate the conversation's copy, and never gate a summary.
2. Review it as written, not as intended. Where a finding conflicts with your
   memory of why you did it, the finding wins — that memory is the bias.
3. State in the report: **author-run review, no independent reviewer**, so the
   verdict is read at its real weight.

A cold re-read is weaker than a fresh reviewer. Say so; never present the two
as equivalent.
```

- [ ] **Step 2: Link it from `SKILL.md`**

In the Gate 1 section, after the `Read [references/plan-gate.md]...` paragraph, add:

```markdown
Run it through a fresh reviewer, not yourself — see
[references/reviewer-separation.md](references/reviewer-separation.md).
```

In the Gate 2 section, after the `Read [references/diff-review.md]...` paragraph, add:

```markdown
Dispatch it to a fresh reviewer per
[references/reviewer-separation.md](references/reviewer-separation.md); an
author reviewing their own diff has every justification still loaded.
```

- [ ] **Step 3: Cross-link from both gate references**

Append one line to `plan-gate.md` and to `diff-review.md`:

```markdown
Who runs this gate: [reviewer-separation.md](reviewer-separation.md).
```

- [ ] **Step 4: Verify**

```bash
cd /Users/karthik/Work/Projects/rkarthik/skills
test -f skills/stage-gate/references/reviewer-separation.md && echo "PASS created"
grep -q "(references/reviewer-separation.md)" skills/stage-gate/SKILL.md && echo "PASS linked" || echo "FAIL one-level-deep"
for f in skills/stage-gate/references/*.md; do b="references/$(basename "$f")"
  grep -q "($b)" skills/stage-gate/SKILL.md || echo "ORPHAN $b"; done; echo "orphan scan done"
grep -q "author-run review" skills/stage-gate/references/reviewer-separation.md && echo "PASS fallback labelled"
```

Expected: three `PASS` lines, no `ORPHAN` output.

- [ ] **Step 5: Commit**

```
git add skills/stage-gate/references/ skills/stage-gate/SKILL.md
git commit -m "feat(stage-gate): separate reviewer from author in Gates 1 and 2"
```

---

### Task 3: Allow gates to chain

**Files:**
- Modify: `skills/stage-gate/SKILL.md` (the `## Picking a gate` section)

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: the sequencing rule Task 4's `"verify and release"` prompt depends on.

- [ ] **Step 1: Replace the no-chaining rule**

Replace:

```markdown
Gates do not chain, and there is no `--full`: each belongs to a different moment
in the cycle, so run only the one matching where the work is.
```

with:

```markdown
Gates may be requested together when one request spans two boundaries —
"verify and release" is `--dev` then `--release`. Run them in cycle order, each
as its own gate with its own artifact, reviewer, and verdict; never merge the
reports. A blocking `--dev` verdict stops the sequence: report it, fix first,
release after. There is still no `--full`, because `--plan` never co-occurs
with the others — by the time there is a diff, the plan gate has passed or been
skipped.
```

- [ ] **Step 2: Verify**

```bash
cd /Users/karthik/Work/Projects/rkarthik/skills
grep -q "Gates do not chain" skills/stage-gate/SKILL.md && echo "FAIL old rule present" || echo "PASS old rule removed"
grep -q "verify and release" skills/stage-gate/SKILL.md && echo "PASS chaining documented"
grep -q "stops the sequence" skills/stage-gate/SKILL.md && echo "PASS stop condition"
```

Expected: three `PASS` lines.

- [ ] **Step 3: Commit**

```
git add skills/stage-gate/SKILL.md
git commit -m "fix(stage-gate): allow --dev and --release to chain"
```

---

### Task 4: Rewrite the indicating prompts

**Files:**
- Modify: `skills/stage-gate/SKILL.md` (frontmatter `description`)
- Modify: `skills/stage-gate/references/memory-hygiene.md` (the gate-trigger block, both copies)
- Modify: `README.md` (new section after the existing Usage block)

**Interfaces:**
- Consumes: chaining from Task 3 (the `"verify and release"` prompt), the plan-path argument from Task 1.
- Produces: nothing later tasks depend on except Task 5's character-count check.

- [ ] **Step 1: Replace the `description` in `SKILL.md`**

The current description is 960 characters and lists skill vocabulary. Replace with prompts a user would actually type, keeping ≤1024:

```yaml
description: >-
  Quality gates for the three boundaries of a feature cycle, run by a fresh
  reviewer rather than the author. --plan gates a written plan — in the
  conversation or a file under docs/plans or specs — for unstated assumptions,
  ambiguity, and unverifiable success criteria. --dev reviews the diff for
  overcomplication and non-surgical changes. --release captures lessons into
  rules and keeps the agent memory file lean. --dev and --release may run in
  sequence. Use when the user says "review my plan", "check the plan before we
  build", "any assumptions I missed", "gate this diff", "review before I push",
  "is this overcomplicated", "did I touch more than I needed", "verify and
  release", "wrap up this feature", "capture lessons", "CLAUDE.md is too long",
  or "set up CLAUDE.md for this repo". Agent-agnostic: CLAUDE.md, AGENTS.md,
  GEMINI.md, or Copilot instructions. --release also bootstraps a new repo.
```

- [ ] **Step 2: Update the gate-trigger block in `memory-hygiene.md`**

Replace **both** occurrences — the one under `### The gate-trigger block` and the one inside the target-shape template — of:

```markdown
## Gates

Run the `stage-gate` skill at each boundary, even when the work looks finished:
plan written → `--plan`, code written before push → `--dev`, merged → `--release`.
```

with:

```markdown
## Gates

Run the `stage-gate` skill at each boundary, even when the work looks finished
— dispatch a fresh reviewer, do not gate your own work:
plan written → `--plan`, code written before push → `--dev`, merged → `--release`.
```

- [ ] **Step 3: Add the indicating-prompts section to `README.md`**

Insert after the existing plain-language trigger paragraph:

````markdown
### Prompts that load it

Copy-paste, or say something close. You do not need the flags.

**Gate the plan — after planning, before code**

> Review my plan before we build.
> Check `docs/plans/2026-08-30-csv-export.md` — anything I haven't stated?
> What assumptions is this plan resting on?

**Gate the diff — after coding, before push**

> Gate this diff before I push.
> Is this overcomplicated?
> Did I touch more than the request needed?

**Hygiene — after merge or release**

> Verify and release.        ← runs --dev then --release
> Wrap up this feature.
> Capture what this cycle taught us.
> CLAUDE.md is getting long.

**Day zero, on a fresh repo**

> Set up CLAUDE.md for this repo.   ← run right after `/init`

The plan gate takes a path, so `review the plan at docs/plans/x.md` targets a
file directly rather than whatever is left in the conversation.
````

- [ ] **Step 4: Verify**

```bash
cd /Users/karthik/Work/Projects/rkarthik/skills
python3 -c "
import re
t=open('skills/stage-gate/SKILL.md').read()
d=re.search(r'description: >-\n((?:  .*\n)+)', t.split('---')[1]).group(1)
d=' '.join(l.strip() for l in d.splitlines())
print(('PASS' if len(d)<=1024 else 'FAIL'), 'description', len(d), 'chars')
"
grep -q "Prompts that load it" README.md && echo "PASS readme section"
grep -c "do not gate your own work" skills/stage-gate/references/memory-hygiene.md   # expect 2
```

Expected: `PASS description` under 1024, `PASS readme section`, count of `2`.

- [ ] **Step 5: Commit**

```
git add skills/stage-gate/SKILL.md skills/stage-gate/references/memory-hygiene.md README.md
git commit -m "docs(stage-gate): rewrite trigger surfaces around real prompts"
```

---

### Task 5: Full validation pass

**Files:**
- No edits unless a check fails.

**Interfaces:**
- Consumes: every preceding task.

- [ ] **Step 1: Run the repo's verification suite**

```bash
cd /Users/karthik/Work/Projects/rkarthik/skills
echo "--- spec: name / description / body ---"
python3 -c "
import re
p='skills/stage-gate/SKILL.md'; t=open(p).read(); fm=t.split('---')[1]
name=re.search(r'^name: (.+)$',fm,re.M).group(1).strip()
d=re.search(r'description: >-\n((?:  .*\n)+)',fm).group(1)
d=' '.join(l.strip() for l in d.splitlines())
body=len(t.splitlines())
print(('PASS' if name=='stage-gate' else 'FAIL'),'name matches dir:',name)
print(('PASS' if 0<len(d)<=1024 else 'FAIL'),'description',len(d),'chars')
print(('PASS' if body<500 else 'FAIL'),'body',body,'lines')
"
echo "--- one level deep: every reference linked from SKILL.md ---"
for f in skills/stage-gate/references/*.md; do b="references/$(basename "$f")"
  grep -q "($b)" skills/stage-gate/SKILL.md && echo "  PASS $b" || echo "  FAIL orphan $b"; done
echo "--- links resolve on disk ---"
grep -o '](references/[^)]*)' skills/stage-gate/SKILL.md | tr -d '](' | sed 's/)$//' | sort -u | while read -r p; do
  test -f "skills/stage-gate/$p" && echo "  PASS $p" || echo "  FAIL missing $p"; done
echo "--- the four defects are gone ---"
grep -rq "plan in context" skills/stage-gate/ && echo "  FAIL defect 1" || echo "  PASS defect 1 discovery"
grep -rq "subagent" skills/stage-gate/ && echo "  PASS defect 2 reviewer" || echo "  FAIL defect 2"
grep -q "Gates do not chain" skills/stage-gate/SKILL.md && echo "  FAIL defect 3" || echo "  PASS defect 3 chaining"
grep -q "Prompts that load it" README.md && echo "  PASS defect 4 prompts" || echo "  FAIL defect 4"
```

Expected: every line `PASS`, no `FAIL`.

- [ ] **Step 2: Check code fences balance in every touched file**

```bash
cd /Users/karthik/Work/Projects/rkarthik/skills
for f in skills/stage-gate/SKILL.md skills/stage-gate/references/*.md README.md; do
  python3 -c "
n=open('$f').read().count(chr(96)*3)
print(('PASS' if n%2==0 else 'FAIL'), '$f', n, 'fences')"
done
```

Expected: all `PASS`.

- [ ] **Step 3: Run the registry check**

```bash
cd /Users/karthik/Work/Projects/rkarthik/skills
npx skills add k97/skills --list
```

Expected: `stage-gate`, `apple-appicon`, `discoverability` all listed.

- [ ] **Step 4: Run `/validate-skills`**

Slash command, run manually in session. Expected: all checks PASS for `skills/stage-gate`.

- [ ] **Step 5: Dogfood — gate this plan**

Run `--plan` against this file. It must locate `docs/plans/2026-08-30-stage-gate-redesign.md` via the Task 1 discovery procedure, dispatch a fresh reviewer per Task 2, and name the artifact path in its output. If it gates the conversation instead of the file, Task 1 did not work.

- [ ] **Step 6: Commit**

```
git add -A
git commit -m "chore(stage-gate): validation pass for the redesign"
```

---

## Open decisions

Two assumptions in this plan. Both reversible; flag before Task 2 if either is wrong.

1. **Subagent dispatch is preferred, not required.** The fallback is a labelled cold re-read. Requiring a subagent would give a stronger gate on Claude Code and break the skill on Copilot. This plan takes graceful degradation.
2. **`reviewer-separation.md` is a new reference rather than SKILL.md prose.** Costs Gates 1 and 2 an extra file read; saves every `--release` invocation from loading content it cannot use.

## Out of scope

- Hooks or harness-level enforcement — Claude Code only, breaks agent-agnosticism.
- Trimming the `SKILL.md` body (discussed 2026-08-30). Real waste, since it re-loads per invocation, but independent of these four defects. Separate plan.
- Adding the `## Gates` block to this repo's own `CLAUDE.md`. That is a `--release` run, not a code change.
