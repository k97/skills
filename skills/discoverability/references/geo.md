# GEO — Generative Engine Optimisation

Loaded by Phase 2 of `discoverability`. Concerns being **cited** in AI-generated answers, not
ranked in blue links.

## What the research actually says

[*GEO: Generative Engine Optimization*](https://arxiv.org/abs/2311.09735), Aggarwal,
Murahari, Rajpurohit, Kalyan, Narasimhan, Deshpande — KDD 2024. Nine optimisation methods
tested across 10,000 queries on a purpose-built benchmark (GEO-bench).

**Lifted citation visibility, by up to 40%:**

1. **Statistics addition** — replacing qualitative claims with specific figures.
2. **Quotation addition** — direct quotes from credible sources.
3. **Cite sources** — inline citations to authoritative references.

**Did not help:** keyword stuffing. Efficacy varied by domain — the gains were largest in
factual and historical queries, smaller in debate-style ones.

### What the study did *not* test

It did not test schema.org types, and it established no citation-yield ordering among them.
Any source ranking `FAQPage` above `Product` "per Princeton research" is inventing that.
Schema makes facts machine-extractable, which plausibly helps, but say so as a mechanism,
not as a measured result.

Practical consequence: **content rewriting beats schema work** for citation. Do the schema
because it is cheap and correct; do the statistics because that is what was measured.

## Bot access — check first

Everything else is moot if the crawlers cannot fetch the page. Names are matched literally;
a typo silently fails open or closed depending on your other rules.

| Bot | Operator | Purpose |
|---|---|---|
| `GPTBot` | OpenAI | model training |
| `OAI-SearchBot` | OpenAI | ChatGPT search results |
| `ClaudeBot` | Anthropic | crawling |
| `Claude-SearchBot` | Anthropic | search results |
| `PerplexityBot` | Perplexity | index building |
| `Google-Extended` | Google | Gemini grounding |
| `Bingbot` | Microsoft | Bing and Copilot |

`Google-Extended` controls Gemini only. It does not affect normal Google Search indexing —
blocking it does not deindex the site, and allowing it does not improve rankings.

Note the distinction between training crawlers (`GPTBot`, `Google-Extended`, `ClaudeBot`)
and answer-time search crawlers (`OAI-SearchBot`, `Claude-SearchBot`, `PerplexityBot`).
A site can allow citation while disallowing training. If the user has a view on training,
ask rather than assume.

## Content work, in priority order

1. **Make claims quantitative.** "Fast" cites poorly; "starts in under 200 ms on an M1"
   cites well. Every marketing adjective is a candidate for a number.
2. **Attribute the numbers.** A figure with a source outperforms a bare figure. Link the
   benchmark, the changelog, the docs page.
3. **Answer the questions actually asked.** AI engines receive comparison and alternative
   prompts constantly: "X vs Y", "best X for Y", "[product] alternative". A structured
   comparison table covering features and pricing is high-citation content and most sites
   do not have one.
4. **Stat-dense FAQ.** Four to six answers, each containing a specific figure or version
   number. Surface them on the highest-traffic page via `FAQPage` JSON-LD, not only on a
   buried support page.
5. **Link the orphans.** Testimonials, case studies, and comparison pages that nothing
   links to are invisible to crawlers and citation engines alike.

## Schema work

Cheap, correct, and it makes facts extractable. Order by what is missing outright rather
than by an invented citation ranking. Copy-paste blocks: [schema-recipes.md](schema-recipes.md).

- `Organization` and `WebSite` — root layout. Establishes the entity behind the site.
- `SoftwareApplication` or `Product` — the thing being sold, with every field wired to a
  real data source.
- `FAQPage` — the highest-traffic page, using the stat-dense answers above.
- `BreadcrumbList` — nested guide and doc routes.
- `VideoObject` — demo and feature videos.

Link entities with `@id` so engines resolve them as one graph rather than several
unrelated blobs. The recipes file shows this.

## i18n and hreflang

Cookie-only or session-only locale detection means translated content has no crawlable URL.
It cannot be cited, because it cannot be fetched. This is a product decision, not a fix
to apply during Phase 3. Present the options with their cost:

1. **Accept.** Translations serve conversion, not acquisition. Zero cost.
2. **Locale subpaths + hreflang.** `/fr/pricing` alongside `/pricing`. Moderate cost;
   routing and a sitemap per locale.
3. **Full URL-based i18n migration.** Highest cost, highest ceiling.

## Reporting

Group findings as:

- **Schema gaps** — the missing field, and the fact it would have made extractable.
- **Content opportunities** — the specific query an AI engine receives that this page
  would answer.
- **Architecture decisions** — needs product input, with options and cost.

Do not report a projected traffic lift. Citation behaviour is not measurable from the
codebase, and a fabricated percentage undermines the findings that are real.
