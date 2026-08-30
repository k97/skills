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
