# Technical SEO audit — full checklist

Loaded by Phase 1 of `discoverability`. Run the scripts first; use this to explain and locate
what they surface, and to cover what they cannot see.

## 1. Crawlability and indexation

- `robots.txt` / `robots.ts` — production allows all bots; staging and preview
  deployments return `noindex` (check the host, not the branch name).
- A `Disallow` that blocks a page which is also a canonical target is a contradiction:
  the crawler cannot fetch the page to read the canonical.
- XML sitemap exists, is referenced from `robots.txt`, and every `<loc>` returns 200.
  A sitemap URL that 301s or 404s wastes crawl budget and is a common silent regression.
- Sitemap excludes session, cart, thank-you, and search-result pages.
- No accidental `noindex` on revenue-critical pages. Grep for `noindex` and read each hit.
- Locale URLs are reachable by Googlebot. Cookie-only i18n means translated content has
  no crawlable URL and effectively does not exist for search.

## 2. Metadata

- Titles unique per page, roughly 30–60 characters, with no brand suffix duplicated by a
  template that the page already applied.
- Meta descriptions unique per page, roughly 70–160 characters.
- `alternates.canonical` on every route. Self-referencing canonicals are correct and
  expected — a missing canonical is the problem, not a self-referencing one.
- `metadataBase` configured, so relative OG image paths resolve to absolute URLs.
- Per-page `openGraph` and `twitter` blocks. Inheriting `og:url` from the root layout
  means every page shares the homepage URL in link previews.
- One canonical tag per page. Two canonicals means search engines ignore both.
- `noindex` and a canonical on the same page contradict each other. Pick one.

## 3. Canonical chains

- A canonical must point at a URL that returns 200. If it points at a redirect, the
  signal is diluted or dropped.
- Canonical target must not itself canonicalise elsewhere. Chains are not followed.
- Canonical host must exactly match the host the site actually serves after redirects,
  including the `www` prefix and the scheme. `audit-meta.mjs` checks this automatically.

## 4. Structured data

Detect with [scripts/extract-jsonld.mjs](../scripts/extract-jsonld.mjs). Confirm rich-result eligibility in Google's Rich
Results Test — the linter checks structure, only Google decides what earns a rich result.

- `SoftwareApplication` / `Product` complete: description, url, applicationCategory,
  operatingSystem, offers, downloadUrl, author, publisher.
- `aggregateRating` only when backed by review data visible on the same page. An
  unverifiable rating is a manual-action risk, not a quick win.
- `Organization` and `WebSite` in the root layout, not repeated per page.
- `FAQPage` on support and FAQ pages.
- `BreadcrumbList` on nested routes, with `position` starting at 1 and incrementing by 1.
- All schema URLs absolute. Relative URLs in JSON-LD are invalid.

## 5. On-page

- Exactly one `<h1>` per page; heading levels descend without skipping.
- Every `<img>` has an `alt` attribute. Decorative images use `alt=""` — an omitted
  attribute and an empty one mean different things to a screen reader.
- No orphan pages: anything in the sitemap should be reachable by following links from
  the homepage. Orphans are invisible to crawlers and to AI citation engines.
- Renamed or merged routes have redirects. Deleted routes return 404, not a soft 404
  (a 200 response rendering "not found" text).

## 6. Conversion and session pages

- Post-purchase, thank-you, and session-token pages: `robots: { index: false, follow: true }`.
- No duplicated brand suffix on checkout-adjacent titles.

## 7. Redirect and canonical-host integrity

Detect with [scripts/redirect-trace.sh](../scripts/redirect-trace.sh). The hard rule — never add an app-level host
redirect, remove the one that loops — is in [SKILL.md](../SKILL.md). What follows is where to look.

### Where host redirects hide

| Layer | Files to check |
|---|---|
| Framework | `next.config.{js,ts,mjs}` `redirects()`/`rewrites()`; Nuxt `routeRules`; SvelteKit `hooks.server.ts`; Astro `redirects`; Remix loaders; Gatsby `createRedirect` |
| Edge / middleware | `middleware.ts`, `_middleware`, Cloudflare Workers, Netlify and Lambda edge functions — anything reading `req.headers.host` and returning a 3xx |
| Platform config | `vercel.json` (`redirects`, `cleanUrls`, `trailingSlash`); `netlify.toml` and `_redirects`; `_headers`; `.htaccess` `RewriteRule`/`RewriteCond`; nginx `return 301`; Cloudflare Redirect Rules and Page Rules; `firebase.json` `hosting.redirects` |
| DNS / registrar | Domain forwarding rules set at the registrar, invisible in the repo entirely |

### The canonical host string

The same host must appear in all of: `metadataBase`, `<link rel="canonical">`, sitemap
`<loc>` URLs, `robots.txt` `Host:` and `Sitemap:` lines, and `og:url` / `twitter:url`.
Any disagreement splits ranking signals and is a High finding even without a loop.

### Severity

- Loop (`ERR_TOO_MANY_REDIRECTS`, curl exit 47) → **Critical**. The site is down.
- Apex and www both serving 200 without one redirecting to the other → **High**.
- Canonical host disagreeing with the landed host → **High**.
- Any app-level www↔apex, http↔https, or trailing-slash redirect → **High**, pending
  confirmation of what the platform already does. Do not assume the direction.

## 8. hreflang, when locale URLs exist

- Every `hreflang` link is reciprocal: if `/en` points to `/fr`, `/fr` must point back.
- Each locale includes a self-referencing `hreflang`.
- Values are valid: `en`, `en-GB`, `x-default`. `en-UK` is not a language tag.
- `hreflang` targets return 200 and are not `noindex`.

## 9. Explicitly out of scope

State this in the report. A reader will otherwise assume it was covered.

- Search Console coverage, impressions, and manual actions.
- Core Web Vitals **field** data (CrUX). Lab metrics from Lighthouse are not a substitute.
- Backlink profile and domain authority.
- Anything rendered only after client-side JavaScript executes, unless checked in a browser.
