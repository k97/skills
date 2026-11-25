# What a gate leaves behind, and committing it

Every gate leaves files: `--plan` and `--dev` save their report, and `--release` edits the memory file and rules. This file decides where reports go, whether those files get committed, and how. It is the single source for all three. The other references only point here.

## The preference

One line in the project memory file, below the gate-trigger line in `## Gates` (see [memory-hygiene.md](memory-hygiene.md)):

```markdown
Gate commits: auto
```

- `auto`: commit the files this gate run wrote, and only those.
- `off`: write them and stop. Review and commit belong to the user.

Resolve it in this order:

1. **The project memory file.**
2. **The user's global instructions** (`~/.claude/CLAUDE.md` or the host's equivalent). These are already in your context; you don't need to read a file to find the line.
3. **Unset: ask once.** Ask "Commit the files stage-gate writes in this project? auto / off", then record the answer as the line above. Recording it is a write by this gate run, so under `auto` the same commit includes it. Where to record it:
   - The memory file has a `## Gates` section → add the line under the trigger line.
   - The memory file exists but has no `## Gates` section → append the whole block from [memory-hygiene.md](memory-hygiene.md) with the line under it.
   - There is no memory file → use the answer for this run only. Don't create the file: `--release` bootstraps it, and it will ask again. Say so in the report.
   - The host can't ask (headless, scheduled, no question tool) → treat this run as `off`, record nothing, and say so.

## Report files (`--plan` and `--dev` only)

`--release` saves no report. Its output is its edits.

- **Path:** `docs/reviews/YYYY-MM-DD-<gate>-<slug>.md`. For `--plan`, the slug is the plan file's stem, or `conversation` when the plan was only in the chat. For `--dev`, it is the branch name with every character outside `[A-Za-z0-9._-]` replaced by `-` (`feat/x` → `feat-x`), or the short SHA on a detached HEAD. If the name is taken, append `-2`, `-3` and so on. Never overwrite an earlier report.
- **Content:** the gate's standard output exactly as the reviewer returned it, unedited, under a header that gives the artifact and pinned ref, and the reviewer path (independent, or `author-run review, no independent reviewer`). The file carries no `Commit:` line, because its own commit SHA doesn't exist until after it is written.
- **Who writes it:** you, the orchestrator. The dispatched reviewer is read-only.
- Show the report in the conversation as well. The file is a copy, not a replacement.
- A gate never reviews `docs/reviews/`. `--dev` leaves it out of the diff, and gate inference ignores it (see SKILL.md).

## Committing (`auto` only)

One commit per gate run, not one per file. When `--dev` and `--release` run in sequence, each makes its own commit, just as each produces its own report.

1. **Snapshot before writing.** Run `git status --porcelain --untracked-files=all` on the whole tree before the gate writes anything. Without `--untracked-files=all`, an untracked folder shows as one line (`?? docs/`) and the files inside it can't be matched. A path that is already dirty there was touched by the user. Never commit it, even if the gate edits it afterwards; committing it would carry the user's edits under the gate's message. List those paths in the report.
2. **Refuse states that aren't plain.** Skip the commit, keeping the files written, when any of `MERGE_HEAD`, `rebase-merge`, `rebase-apply`, `CHERRY_PICK_HEAD`, `REVERT_HEAD` or `BISECT_LOG` exists under `git rev-parse --git-path <name>`, or when `git symbolic-ref -q HEAD` fails (detached HEAD).
3. **Collect the paths:** what this run wrote, minus the user-touched paths, minus anything `git check-ignore -q -- <path>` reports as ignored. Run the ignore check before `git add`, which errors on ignored paths. For a symlinked memory file, use the canonical path ([agents.md](agents.md)). If nothing is left, skip.
4. **Commit just those paths:** `git add -- <paths>`, then `git commit -m "<message>" -- <paths>`. With a pathspec, git commits only those paths and leaves anything else the user staged out of the commit.
5. **Message:** match the convention in `git log -n 20 --format=%s`, for example `chore: capture this cycle's lessons into the testing rule` or `docs: --dev review of feat-x at a1b2c3d`. If the log shows no convention, use `chore(stage-gate): <gate> — <one line>`.
6. **Never** push, amend, pass `--no-verify`, or change signing settings. If a hook fails, or the commit waits on input such as a signing passphrase, run `git restore --staged -- <paths>` so the index is as you found it, leave the files written, and report the hook's output. Don't retry.

Verified on git 2.54:

- The pathspec commit leaves the user's other staged work out of the commit.
- `git add` exits 1 on an ignored path.
- A failed pre-commit hook leaves the gate's `git add` staged, and `git restore --staged` undoes it.
- A pathspec commit is refused during a merge anyway: `cannot do a partial commit during a merge`.

## Report line

The report shown in the conversation ends with exactly one of these (the saved file doesn't):

- `Commit: <short-sha> <subject>`
- `Commit: skipped — <reason>` (naming any user-touched or ignored paths left out)
- `Commit: off`
