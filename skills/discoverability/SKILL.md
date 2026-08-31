---
name: discoverability
description: >-
  Technical SEO audit, GEO (AI-citation) review, and in-codebase SEO fixes for web projects. Use for SEO audit, GEO review, AI search optimisation or optimization, "not cited by AI", schema, JSON-LD, structured data, technical SEO, not ranking, redirect loop, ERR_TOO_MANY_REDIRECTS, canonical host, www vs apex, sitemap, robots.txt, meta tags. Scope with --audit, --geo, --fix, --full.
argument-hint: "[url|path] [--audit|--geo|--fix|--full] [--routes /a,/b]"
source: https://github.com/k97/skills/tree/main/skills/discoverability
metadata:
  version: "0.1.0"
---

# discoverability

Audit, then GEO review, then apply fixes. Next.js / TypeScript defaults; follow whatever the repo already uses. `${CLAUDE_SKILL_DIR}` is this skill's directory — the working directory is the user's project, so address bundled files through it.

| Flag      | Phase                                 | Writes code |
| --------- | ------------------------------------- | ----------- |
| `--audit` | 1 — technical SEO                     | no          |
| `--geo`   | 2 — AI-citation readiness             | no          |
| `--fix`   | 3 — apply findings already in context | yes         |
| `--full`  | 1 → 2 → 3 _(default)_                 | yes         |

`--routes /,/pricing` narrows scope; default is every route.

## Setup

- Prefer a local path _and_ a live URL. Each catches what the other cannot.
- Read `.agents/product-marketing.md` or `.claude/product-marketing.md` if either exists. Ask only what it does not answer.
- `--fix` needs reports in context. If absent, run `--full`.

## Scripts

Needs `curl` and Node 18+, nothing to install. Run these before reading source: they produce the evidence, source inspection explains it. Each exits non-zero on an error-level finding. Add `--json` to the Node scripts for structured output.

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/redirect-trace.sh" example.com /pricing /blog
node "${CLAUDE_SKILL_DIR}/scripts/extract-jsonld.mjs" https://example.com/pricing
node "${CLAUDE_SKILL_DIR}/scripts/audit-meta.mjs" https://example.com/pricing
node "${CLAUDE_SKILL_DIR}/scripts/audit-meta.mjs" out/pricing.html --base https://example.com
```

Pass real routes to `redirect-trace.sh` — loops often hide on deep paths, not on `/`.

All three read server-rendered HTML only. Client-injected JSON-LD is invisible to them, as it is to `web_fetch`. Never write "no schema found" on a script's say-so; confirm in a browser.

## Phase 1 — technical audit (`--audit`)

Read [references/technical-audit.md](references/technical-audit.md) and work its checklist. Run the scripts first, then use source to locate and explain each finding.

Report per finding:

```
File: app/page.tsx:37-41
Severity: Critical | High | Medium | Low
Root cause: <one sentence>
Impact: <what breaks in search, social, or AI citation>
Fix: <minimal change, file + line>
Effort: <5 min | 30 min | product decision>
```

Group by severity, then close with a table: `# | Finding | Severity | Effort | Blocks release?`

## Phase 2 — GEO review (`--geo`)

Read [references/geo.md](references/geo.md). JSON-LD to copy: [references/schema-recipes.md](references/schema-recipes.md).

Check bot access first — if the crawlers are blocked, nothing else in this phase matters.

Two claims to never make: that schema types have a citation-yield ranking "per Princeton research" (that study tested content tactics, not schema), and any projected traffic lift. Neither is observable from a codebase, and inventing them discredits the real findings.

Group output as **Schema gaps**, **Content opportunities**, **Architecture decisions**.

## Phase 3 — fix (`--fix`)

Applies the Phase 1 and Phase 2 findings. **Edit the working tree and stop** — no `git add`, no `git commit`. Review and commit belong to the user.

- Match the repo's framework, file layout, and spelling. Do not impose a dialect.
- Name the exact file and line before each edit. Minimal change, no drive-by refactors, no `any`.
- Wire schema fields to real data sources; never hardcode a value that drifts.
- Never invent an `aggregateRating`. Remove it and list it under "needs real data".
- Skip i18n architecture, copy outside schema descriptions, and anything the report marks as needing product input.

**Host redirects — hard rule.** An app-level `www`↔apex, `http`↔`https`, or trailing-slash redirect that duplicates one the hosting platform already performs will ping-pong, produce `ERR_TOO_MANY_REDIRECTS`, and take the site down. Leave host canonicalisation to the platform. Fix a loop by _removing_ the app-level redirect, never by adding another. When canonical and landed host merely disagree, change the metadata to match the host actually served — not the redirect to match the metadata.

Batch 1: every Critical, High, and Medium finding from Phase 1, in severity order. Batch 2: the Phase 2 schema work.

**Verify before reporting done.** Never claim success on the strength of the edits alone.

1. The project builds (`npm run build`, or whatever the repo uses).
2. `extract-jsonld.mjs` lints clean against the built HTML or a dev server.
3. `audit-meta.mjs` passes on every changed route.
4. `redirect-trace.sh`, if any redirect was touched.

Report any step you could not run, and why.

Output sections: **Changed** (by batch), **Verification**, **Needs a product decision**, **Needs real data**.
