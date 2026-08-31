# JSON-LD recipes

Loaded by Phase 2 and Phase 3. Every block below lints clean under [scripts/extract-jsonld.mjs](../scripts/extract-jsonld.mjs).

## Rules that apply to all of them

- Every URL is absolute. Relative URLs in JSON-LD are invalid.
- Wire values to real data. A hardcoded `softwareVersion` drifts within one release.
- Link entities by `@id` so engines resolve one graph, not several unrelated blobs. Convention below: `{origin}/#organization`, `{origin}/#website`.
- Never emit an `aggregateRating` unless review data is visible on the same page.

## Root layout — Organization + WebSite

Emit once, in the root layout. Not per page.

```json
{
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "Organization",
      "@id": "https://example.com/#organization",
      "name": "Acme",
      "url": "https://example.com",
      "logo": "https://example.com/logo.png",
      "sameAs": ["https://github.com/acme", "https://x.com/acme"]
    },
    {
      "@type": "WebSite",
      "@id": "https://example.com/#website",
      "name": "Acme",
      "url": "https://example.com",
      "publisher": { "@id": "https://example.com/#organization" },
      "potentialAction": {
        "@type": "SearchAction",
        "target": {
          "@type": "EntryPoint",
          "urlTemplate": "https://example.com/search?q={search_term_string}"
        },
        "query-input": "required name=search_term_string"
      }
    }
  ]
}
```

`potentialAction` only earns a sitelinks searchbox if the site really has a search page at that URL. Omit it otherwise.

## SoftwareApplication

```json
{
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  "name": "Acme Pro",
  "description": "Records terminal sessions and replays them as shareable links.",
  "url": "https://example.com",
  "applicationCategory": "DeveloperApplication",
  "operatingSystem": "macOS 14+, Windows 11",
  "softwareVersion": "2.4.1",
  "downloadUrl": "https://example.com/download",
  "author": { "@id": "https://example.com/#organization" },
  "publisher": { "@id": "https://example.com/#organization" },
  "offers": {
    "@type": "Offer",
    "price": "0",
    "priceCurrency": "USD",
    "availability": "https://schema.org/InStock"
  }
}
```

For paid software use the real `price`. `"price": "0"` on a paid product is worse than omitting `offers`.

## Product

```json
{
  "@context": "https://schema.org",
  "@type": "Product",
  "name": "Acme Pro",
  "description": "Terminal session recording for teams.",
  "image": "https://example.com/product.png",
  "brand": { "@id": "https://example.com/#organization" },
  "offers": {
    "@type": "Offer",
    "url": "https://example.com/pricing",
    "price": "49.00",
    "priceCurrency": "USD",
    "availability": "https://schema.org/InStock"
  }
}
```

### aggregateRating — only with real data

Add this to a `Product` **only** when the same page renders the reviews it summarises, and both numbers come from a live source:

```json
"aggregateRating": {
  "@type": "AggregateRating",
  "ratingValue": "4.7",
  "reviewCount": "128"
}
```

If there is no review data, there is no rating. Remove the block and report it under "needs real data". Fabricated ratings are a manual-action risk.

## FAQPage

Four to six answers, each carrying a specific figure. Put it on the highest-traffic page, not only the support page.

```json
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [
    {
      "@type": "Question",
      "name": "How much CPU does Acme Pro use while recording?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Under 0.1% CPU on an M1 MacBook Air during a 60-minute recording."
      }
    },
    {
      "@type": "Question",
      "name": "Which operating systems does Acme Pro support?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "macOS 14 and later, and Windows 11. Linux support is in beta as of v2.4."
      }
    }
  ]
}
```

`extract-jsonld.mjs` emits an INFO for any answer containing no digits — that is the signal to rewrite it as a figure.

## BreadcrumbList

`position` starts at 1 and increments by 1. The linter enforces this.

```json
{
  "@context": "https://schema.org",
  "@type": "BreadcrumbList",
  "itemListElement": [
    {
      "@type": "ListItem",
      "position": 1,
      "name": "Home",
      "item": "https://example.com"
    },
    {
      "@type": "ListItem",
      "position": 2,
      "name": "Support",
      "item": "https://example.com/support"
    },
    { "@type": "ListItem", "position": 3, "name": "Installing" }
  ]
}
```

The final crumb is the current page and omits `item`.

## VideoObject

```json
{
  "@context": "https://schema.org",
  "@type": "VideoObject",
  "name": "Acme Pro in 90 seconds",
  "description": "A walkthrough of recording, trimming, and sharing a session.",
  "thumbnailUrl": "https://example.com/video-thumb.jpg",
  "uploadDate": "2026-03-14T08:00:00+00:00",
  "duration": "PT1M30S",
  "contentUrl": "https://example.com/demo.mp4",
  "publisher": { "@id": "https://example.com/#organization" }
}
```

`duration` is ISO 8601. `PT1M30S` is ninety seconds.

## Emitting it — Next.js App Router

Serialise from a typed object rather than hand-writing a template string, so the data stays wired to its source.

```tsx
import type { WithContext, SoftwareApplication } from "schema-dts";

const schema: WithContext<SoftwareApplication> = {
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  name: pkg.displayName,
  softwareVersion: pkg.version,
  url: siteUrl,
  downloadUrl: `${siteUrl}/download`,
};

export default function Page() {
  return (
    <script
      type="application/ld+json"
      // Serialised, not interpolated: JSON.stringify escapes the content.
      dangerouslySetInnerHTML={{ __html: JSON.stringify(schema) }}
    />
  );
}
```

`schema-dts` is optional but makes missing required fields a type error. If the repo does not already depend on it, do not add it during Phase 3 — type the object locally instead.

## Validating

```bash
node scripts/extract-jsonld.mjs https://example.com/pricing
```

Then confirm eligibility for rich results in Google's Rich Results Test. The linter checks structure; only Google decides what earns a rich result.
