# k97/skills

Agent Skills for AI coding agents, built on the [Agent Skills](https://agentskills.io) open standard — installable in Claude Code, Cursor, Codex, Copilot, Gemini CLI, and ~20 other agents.

| Skill | What it does |
|---|---|
| [**`codebase-seo`**](skills/codebase-seo/) | Technical SEO audit → GEO (AI-citation) review → applies the fixes in your codebase. Ships scripts that trace redirect loops and lint JSON-LD. |

## Install

```bash
npx skills add k97/skills --list                  # see what's in here
npx skills add k97/skills --skill codebase-seo    # install one skill
```

`skills add` takes the **repo path**, not the skill name. Requirements vary per skill; `codebase-seo` needs `curl` and Node 18+, with nothing to `npm install`.

> **Claude Code, in a project with no `.claude/` directory yet:** the CLI writes the canonical copy to `.agents/skills/` and skips the `.claude/skills/` symlink, even though it reports "Installing to: … Claude Code". Run `mkdir -p .claude` first, or install globally with `-g`, and the symlink appears as expected.

Or copy a skill in manually:

```bash
git clone https://github.com/k97/skills /tmp/k97-skills

mkdir -p .claude/skills                                  # this project only
cp -r /tmp/k97-skills/skills/codebase-seo .claude/skills/

mkdir -p ~/.claude/skills                                # or: everywhere
cp -r /tmp/k97-skills/skills/codebase-seo ~/.claude/skills/
```

Start a new session and `/codebase-seo` is available.

---

# codebase-seo

Takes a web project from **audit → AI-citation review → applied fixes** in one workflow. Built for Next.js / TypeScript by default, and adapts to whatever framework it finds.

Unlike prompt-only SEO skills, it ships **three dependency-free scripts** so the audit produces evidence rather than guesses: a live redirect-chain tracer, a JSON-LD linter, and a metadata auditor that checks canonical hosts against the host your site *actually serves*.

## Usage

```bash
/codebase-seo ./my-app                          # audit → GEO review → apply fixes (default)
/codebase-seo ./my-app --audit                  # technical audit only, no code changes
/codebase-seo ./my-app --geo                    # AI-citation review only
/codebase-seo --fix                             # apply fixes from reports already in context
/codebase-seo ./my-app --routes /,/pricing      # narrow the scope
```

It also triggers on plain language: *"run an SEO audit"*, *"why aren't we cited by AI"*, *"improve our schema"*, *"we have a redirect loop"*, *"www vs apex"*.

If you keep a product brief at `.agents/product-marketing.md` or `.claude/product-marketing.md`, the skill reads it before asking you anything.

## The three phases

| Phase | Flag | What it does | Touches code |
|---|---|---|---|
| **1 · Technical audit** | `--audit` | Metadata, robots, sitemap, JSON-LD, on-page, canonical chains — plus a live redirect trace across apex, www, and your real routes. Findings grouped by severity with a prioritised plan. | no |
| **2 · GEO review** | `--geo` | Whether ChatGPT, Perplexity, Gemini, and Claude can reach, parse, and cite you. Bot access, schema completeness, content tactics. | no |
| **3 · Fix** | `--fix` | Applies the findings in your codebase, then re-runs the scripts to verify. Leaves the commit to you. | yes |
| **All three** | `--full` *(default)* | 1 → 2 → 3. | yes |

## The scripts

They run standalone, so you can use them without the skill:

```bash
cd skills/codebase-seo

# Redirect chains for apex + www + each route. Catches ERR_TOO_MANY_REDIRECTS
# before your users do. Loops often hide on deep paths, not on "/".
bash scripts/redirect-trace.sh example.com /pricing /blog

# Extract, parse, and lint every server-rendered JSON-LD block.
node scripts/extract-jsonld.mjs https://example.com

# Title, description, canonical, OG/Twitter, robots, h1, image alt.
node scripts/audit-meta.mjs https://example.com/pricing
node scripts/audit-meta.mjs out/pricing.html --base https://example.com
```

Each exits non-zero on an error-level finding, so they drop straight into CI. The Node scripts take `--json`.

**What they catch that a prompt won't:** relative URLs in JSON-LD, `aggregateRating` without a review count, breadcrumb positions out of order, two canonical tags on one page, a page that is both `noindex` and canonical, a title whose template suffix collides with itself, and — the big one — a canonical host that disagrees with the host the request lands on.

**What they can't see:** anything injected by client-side JavaScript. They read server-rendered HTML, same as `web_fetch`. The skill says so explicitly rather than reporting "no schema found."

## Why the redirect check exists

The most common way to take a site fully down on deploy day is an app-level host redirect (`www`↔apex, `http`↔`https`, trailing slash) that duplicates one your hosting platform already performs. The two ping-pong, and every URL returns `ERR_TOO_MANY_REDIRECTS`.

It is invisible from source, because neither redirect is wrong on its own. `redirect-trace.sh` finds it, and the skill's hard rule is to *remove* the app-level redirect rather than add another.

## A note on GEO claims

Plenty of SEO advice ranks schema types by "citation yield, per Princeton research." The [Princeton GEO paper](https://arxiv.org/abs/2311.09735) (Aggarwal et al., KDD 2024) tested nine **content** tactics across 10,000 queries. Adding statistics, quotations, and cited sources lifted visibility by up to 40%. Keyword stuffing did nothing. It never tested schema types and established no ordering among them.

This skill cites the paper for what it found, treats schema as a cheap correctness measure rather than a measured ranking lever, and does not project traffic numbers it cannot observe.

## Credits

Assembled and extended by [@k97](https://github.com/k97), drawing on:

- **[coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills)** — `seo-audit`, `ai-seo`, `schema`, `cro`
- **[ReScienceLab/opc-skills](https://github.com/ReScienceLab/opc-skills)** — `seo-geo`

`codebase-seo` adds the live redirect and canonical-host tooling, the JSON-LD linter, and the in-codebase fix phase. For narrower single-purpose tools, the collections above are the place to look.

---

## Repo layout

```
k97/skills
└── skills/
    └── codebase-seo/
        ├── SKILL.md
        ├── references/
        │   ├── technical-audit.md    # full Phase 1 checklist
        │   ├── geo.md                # Phase 2 depth + bot table
        │   └── schema-recipes.md     # copy-paste JSON-LD, lint-clean
        └── scripts/
            ├── redirect-trace.sh
            ├── extract-jsonld.mjs
            └── audit-meta.mjs
```

The registry CLI walks root `SKILL.md`, `skills/<name>/SKILL.md`, or `skills/<category>/<name>/SKILL.md`. Anything else is invisible to `npx skills add`.

Skills are structured around [progressive disclosure](https://agentskills.io), so each costs almost nothing until you use it:

| Layer | When it loads | Cost |
|---|---|---|
| `description` | every session, for every installed skill | ~96 tokens |
| `SKILL.md` body | on invocation, then stays all session | ~1,285 tokens |
| `references/*.md` | only when a phase reads one | 0 until read |
| `scripts/*` | executed, never read into context | 0 — only their output counts |

So an `--audit` run never pays for the GEO reference, and no run ever pays for the ~4,700 tokens of script source. The scripts print findings rather than confirmations for the same reason: their stdout is the part that lands in the context window.

## License

[MIT](LICENSE) © 2026 Karthik ([@k97](https://github.com/k97))
