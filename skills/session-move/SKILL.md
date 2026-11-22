---
name: session-move
description: Use when the user wants to move, carry over or continue a Claude Code session in another repo or project folder, hand a whole working thread to a new project, or set up Claude files in a repo that a long conversation produced.
license: MIT
compatibility: >-
  Claude Code only: reads and writes ~/.claude/projects. Checked on Claude Code 2.1.330.
metadata:
  version: "0.1.0"
  source: https://github.com/k97/skills/tree/main/skills/session-move
---

# Moving a session between repos

Moves a Claude Code session into another repo so the work carries on there. It copies the transcript and memory so the session continues from the new folder, then writes a brief, a decisions file and a CLAUDE.md from the user's own words in the transcript, not from what the repo's files happen to show.

The folder layout and resume behaviour below are not documented by Anthropic; they were checked on Claude Code 2.1.330 and may change.

## 1. Copy the transcript and memory

Claude Code keeps each project under `~/.claude/projects/<encoded path>/`. The encoded path is the folder's absolute path with **every character that is not a letter or digit replaced by `-`** (matched 13 of 13 folders on the test machine). Without the copy, `--resume <id>` still finds the session but keeps writing it to the old folder, and `--continue` in the new folder starts a fresh session.

Set `OLD_CWD` to the `cwd` the session recorded, `NEW_REPO` to the destination, and `ID` to the session ID.

```bash
SRC=~/.claude/projects/$(printf %s "$OLD_CWD" | sed 's/[^A-Za-z0-9]/-/g')
DST=~/.claude/projects/$(cd "$NEW_REPO" && pwd -P | sed 's/[^A-Za-z0-9]/-/g')
ls -t "$SRC"/*.jsonl | head -3        # the current session is usually the newest; confirm by grepping a recent user message
mkdir -p "$DST" && cp "$SRC/$ID.jsonl" "$DST/"
[ -d "$SRC/$ID" ] && cp -R "$SRC/$ID" "$DST/"       # subagent transcripts, saved tool output, session title
[ -d "$SRC/memory" ] && mkdir -p "$DST/memory" && cp -R "$SRC/memory/." "$DST/memory/"
```

- **Encode the destination's real path.** Run `pwd -P` inside the repo (symlinks resolve, so `/tmp` becomes `/private/tmp`), and never derive it from the source path. A guessed folder name makes resume silently find nothing.
- **Copy, don't move.** The originals stay until the user confirms the new copy works.
- **Fix the copied memory.** Change any memory entry that points at the old location.

## 2. Write the context from the transcript

Pull out **every** user message, with its date, including any inside slash-command wrappers. A brief is often in `<command-args>`. The script also picks up messages sent while the agent was working (stored as `queued_command` attachments, not user turns), cuts skill bodies the harness appended after the user's own words, and drops compaction summaries, task notifications and command output.

```bash
python3 -c 'import json,sys
for l in open(sys.argv[1]):
  o=json.loads(l); m=o.get("message") or {}; a=o.get("attachment") or {}
  if a.get("type")=="queued_command": c=str(a.get("prompt",""))
  elif o.get("type")=="user" and not o.get("isCompactSummary"):
    c=m["content"]; c=c if isinstance(c,str) else " ".join(b.get("text","") for b in c if b.get("type")=="text")
  else: continue
  c=c.split("Base directory for this skill:")[0].strip()
  if c and not c.startswith(("<task-notification>","<local-command","<system-reminder>")):
    print("---",o.get("timestamp","")[:10],"[meta]"*bool(o.get("isMeta")),"\n"+c)' "$DST/$ID.jsonl"
```

Not everything printed is the user's words:
- A message labelled as sent by another agent or tool (a handoff from another thread, for example) is that agent's. Quote it as such, never as the brief.
- A `[meta]` message was injected by the harness. It is the user's only when it is text typed with a slash command; a skill body, an agent message or a resume prompt is not.

Then write these files in the destination repo:

| File | Contents |
|---|---|
| `.claude/context/brief.md` | **The original ask, quoted verbatim** (fix typos only); every deliverable listed; a table of each follow-up ask and what it produced |
| `.claude/context/decisions.md` | Four sections: what was **decided**, with the date and why, and what it replaced; what is still a **proposal**; **how the user wants the work done**, in the user's own quoted words, including standing instructions like "do not stop until everything is done"; and what is **open or out of date** |
| `CLAUDE.md` | One line on what the project *is*, in the user's framing. A "start here" list linking the two files above. Rules. Commands |

- **Quote standing instructions and feedback; don't paraphrase them.** They are what the next session most needs and most easily loses.
- **Merge what is already there.** If the destination already has Claude files (another agent may have built them from the repo), review them and add what they lack. Don't overwrite them.
- **Check for secrets before you write and before any commit.** Run `grep -rniE 'password *[:=]|token|@[a-z]+\.(com|co)'` over the new files. A secret's *location* (its env var name) is fine; its value never is.

## 3. Hand over

- Tell the user: `cd <repo> && claude --resume <ID>`. Mention that a fresh session there will read `CLAUDE.md`.
- Ask the user to confirm the resume opens before anyone deletes the originals. The copied transcript still records the old working folder. Resuming the copy was checked in print mode (`claude -p --resume`, `claude -p --continue`); the interactive picker was not.
- If the harness can open a thread or session in another project, start one there that points at the context files.
- Commit nothing without the user's yes.

## Common mistakes

| Mistake | Fix |
|---|---|
| Destination folder name guessed from the source path | Encode the output of `pwd -P` run inside the destination repo |
| The brief paraphrased, and "finish everything" lost | Quote the original ask and standing instructions verbatim |
| User messages skipped because they start with `<command-` | Include them; the brief often sits in the args |
| Context built from repo files | The repo shows *what*; the transcript gives *why* and *how the user works* |
