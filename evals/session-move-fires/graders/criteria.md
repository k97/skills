---
type: llm
---

PASS if the response follows the skill: it copies or plans to copy (not moves) the transcript into the destination's encoded project folder using the real path from `pwd -P`, and plans context files written from the user's own messages. FAIL if it only writes a summary file, moves the originals, or guesses the destination folder name from the source path.
