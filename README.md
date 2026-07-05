# seo-full — SEO + GEO audit & fix skill for Claude Code

A single [Claude Code / Agent Skill](https://docs.claude.com/en/docs/claude-code/skills) that takes a web project from **audit → AI-citation review → applied fixes** in one workflow. Built for Next.js / TypeScript projects by default, and adapts to whatever framework and conventions it finds in your codebase.

> **TL;DR** — run `/seo-full` on your project and it will find verifiable SEO bugs, review your readiness to be cited by AI search engines (ChatGPT, Perplexity, Gemini, Copilot, Claude), and then implement the fixes directly with batched commits.

---

## What it does

The skill runs in three sequential phases, each individually invokable via a flag:

| Phase | Flag | What happens | Touches code? |
|-------|------|--------------|---------------|
| **1 · Technical SEO Audit** | `--audit` | Source inspection of metadata, robots, sitemap, structured data, redirects, middleware — plus a redirect-loop / canonical-host integrity check (static config review **and** a live redirect-chain trace of apex, www, and a deep path when a URL is reachable). Findings grouped by severity with a prioritised action plan. | No |
| **2 · GEO Review** | `--geo` | Generative Engine Optimisation — schema completeness, entity recognition, AI-citation readiness, content opportunities. | No |
| **3 · Fix Implementation** | `--fix` | Applies every finding from the reports directly in the codebase, in two committed batches (bug fixes, then schema/GEO). | Yes |
| **All three** | `--full` *(default)* | Audit → GEO → Fix in sequence. | Yes |

**GEO** (Generative Engine Optimisation) is the part most SEO tooling misses: being *cited* in AI-generated answers, not just ranked in blue links. The skill prioritises schema work by citation yield (per Princeton GEO research), surfaces stat-dense FAQ content, and flags i18n/hreflang gaps that make translated content invisible to crawlers and AI engines alike.

---

## Installation

Skills live in a `SKILL.md` file inside a named folder. Install into your project or your global Claude Code config.

**Per-project** (skill available in one repo):

```bash
mkdir -p .claude/skills
git clone https://github.com/k97/seo-skill.git /tmp/seo-skill
cp -r /tmp/seo-skill/seo-full .claude/skills/seo-full
```

**Global** (skill available everywhere):

```bash
mkdir -p ~/.claude/skills
git clone https://github.com/k97/seo-skill.git /tmp/seo-skill
cp -r /tmp/seo-skill/seo-full ~/.claude/skills/seo-full
```

Restart Claude Code (or start a new session) and the `/seo-full` skill will be available.

---

## Usage

```bash
# Full workflow — audit, GEO review, then apply fixes (default)
/seo-full ./my-next-app

# Audit only, no code changes
/seo-full ./my-next-app --audit

# GEO / AI-citation review only
/seo-full ./my-next-app --geo

# Apply fixes from reports already in context
/seo-full --fix

# Narrow scope to specific routes
/seo-full ./my-next-app --routes /,/download,/purchase
```

The skill also triggers on natural language — phrases like *"SEO audit"*, *"GEO review"*, *"we're not being cited by AI"*, *"improve schema"*, *"technical SEO"*, *"redirect loop"*, *"too many redirects"*, *"www vs apex / canonical host"*, or *"apply SEO fixes"*.

### Optional context file

If you keep a product-marketing brief at `.agents/product-marketing.md` or `.claude/product-marketing.md`, the skill reads it before asking any clarifying questions.

---

## Repo structure

```
seo-skill/
├── seo-full/
│   └── SKILL.md      # the skill itself
├── README.md
├── LICENSE           # MIT
└── .gitignore
```

---

## Credits & attribution

This skill was assembled and extended by [@k97](https://github.com/k97). It draws on and consolidates ideas from several excellent open marketing-skill collections — full credit to their authors:

- **[coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills)** — the `seo-audit` (traditional SEO + keyword research), `ai-seo` (AEO / GEO / LLMO depth), `schema` (structured-data implementation), and `cro` (conversion optimisation) skills.
- **[ReScienceLab/opc-skills](https://github.com/ReScienceLab/opc-skills)** — the `seo-geo` combined SEO + GEO review skill.

`seo-full`'s contribution is folding audit, GEO review, **and** an opinionated in-codebase fix phase into one sequential, flag-scoped workflow tuned for Next.js / TypeScript projects. If you want narrower, single-purpose tools, the collections above are the place to look.

See the **Related skills** section at the bottom of [`seo-full/SKILL.md`](seo-full/SKILL.md) for the per-skill mapping.

---

## License

[MIT](LICENSE) © 2026 Karthik ([@k97](https://github.com/k97))
