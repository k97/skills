#!/usr/bin/env node
// extract-jsonld.mjs — extract and lint JSON-LD blocks from URLs or HTML files.
//
// Solves the problem that web-fetch tooling strips <script> tags, so schema is
// invisible to it. This reads the raw HTML.
//
// LIMITATION: catches server-rendered JSON-LD only. Schema injected by
// client-side JS will not appear here. If this reports no blocks but you
// expect some, confirm in a real browser before concluding schema is missing.
//
// Usage:  node extract-jsonld.mjs <url|file> [more...] [--json]
// Exit:   0 no errors · 1 parse error or ERROR-level finding · 2 usage error

import { readFile } from 'node:fs/promises';

const UA = 'Mozilla/5.0 (compatible; discoverability/1.0)';
const BLOCK_RE =
  /<script[^>]+type\s*=\s*["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi;

const URL_KEYS = ['url', 'logo', 'image', 'downloadUrl', 'contentUrl', 'thumbnailUrl', 'sameAs'];

const RECOMMENDED = {
  SoftwareApplication: ['description', 'url', 'applicationCategory', 'operatingSystem', 'offers'],
  Product: ['description', 'image', 'offers', 'brand'],
  Organization: ['url', 'logo', 'sameAs'],
  WebSite: ['url', 'name'],
  Article: ['headline', 'author', 'datePublished', 'image'],
  VideoObject: ['name', 'description', 'thumbnailUrl', 'uploadDate'],
};

const args = process.argv.slice(2);
const asJson = args.includes('--json');
const targets = args.filter((a) => !a.startsWith('--'));

if (targets.length === 0) {
  console.error('Usage: node extract-jsonld.mjs <url|file> [more...] [--json]');
  process.exit(2);
}

async function load(target) {
  if (/^https?:\/\//i.test(target)) {
    const res = await fetch(target, { headers: { 'user-agent': UA }, redirect: 'follow' });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return res.text();
  }
  return readFile(target, 'utf8');
}

/** Every object in the tree, so nested nodes get linted too. */
function allNodes(root) {
  const out = [];
  const walk = (n) => {
    if (Array.isArray(n)) return n.forEach(walk);
    if (!n || typeof n !== 'object') return;
    out.push(n);
    for (const v of Object.values(n)) walk(v);
  };
  walk(root);
  return out;
}

const typesOf = (n) => (n['@type'] ? [].concat(n['@type']) : []);

function lintNode(node, add) {
  const types = typesOf(node);
  if (types.length === 0) return;
  const label = types.join('/');

  for (const key of URL_KEYS) {
    const raw = node[key];
    if (raw === undefined) continue;
    for (const v of [].concat(raw)) {
      if (typeof v === 'string' && v.trim() && !/^https?:\/\//i.test(v)) {
        add('error', `${label}.${key} is relative ("${v}") — schema URLs must be absolute`);
      }
    }
  }

  if (node.aggregateRating) {
    const r = node.aggregateRating;
    const hasCount = r.reviewCount !== undefined || r.ratingCount !== undefined;
    if (r.ratingValue === undefined || !hasCount) {
      add('error', `${label}.aggregateRating needs ratingValue and reviewCount/ratingCount`);
    }
    add(
      'warn',
      `${label}.aggregateRating must be backed by review data visible on the same page. ` +
        `Unverifiable ratings are a manual-action risk — remove it rather than invent one.`,
    );
  }

  if (types.includes('FAQPage')) {
    const qs = [].concat(node.mainEntity ?? []);
    if (qs.length === 0) add('error', 'FAQPage has no mainEntity questions');
    qs.forEach((q, i) => {
      if (!q?.name) add('error', `FAQPage.mainEntity[${i}] missing "name" (the question)`);
      const text = q?.acceptedAnswer?.text;
      if (!text) add('error', `FAQPage.mainEntity[${i}] missing acceptedAnswer.text`);
      else if (!/\d/.test(text)) {
        add('info', `FAQPage.mainEntity[${i}] answer has no figures — stat-dense answers cite better`);
      }
    });
  }

  if (types.includes('BreadcrumbList')) {
    const items = [].concat(node.itemListElement ?? []);
    items.forEach((it, i) => {
      if (Number(it?.position) !== i + 1) {
        add('error', `BreadcrumbList.itemListElement[${i}] position should be ${i + 1}`);
      }
    });
  }

  if (types.includes('WebSite') && !node.potentialAction) {
    add('info', 'WebSite has no potentialAction (SearchAction) — enables sitelinks searchbox');
  }

  for (const t of types) {
    for (const field of RECOMMENDED[t] ?? []) {
      if (node[field] === undefined) add('warn', `${t} missing recommended field "${field}"`);
    }
  }
}

let exitCode = 0;
const report = [];

for (const target of targets) {
  const entry = { target, blocks: [], types: [], findings: [] };
  let html;
  try {
    html = await load(target);
  } catch (err) {
    entry.findings.push({ level: 'error', msg: `could not load: ${err.message}` });
    report.push(entry);
    exitCode = 1;
    continue;
  }

  const raws = [...html.matchAll(BLOCK_RE)].map((m) => m[1]);
  if (raws.length === 0) {
    entry.findings.push({
      level: 'warn',
      msg: 'no server-rendered JSON-LD found — confirm in a browser before reporting "no schema"',
    });
  }

  raws.forEach((raw, i) => {
    const add = (level, msg) => {
      entry.findings.push({ level, msg: `block[${i}] ${msg}` });
      if (level === 'error') exitCode = 1;
    };
    let parsed;
    try {
      parsed = JSON.parse(raw);
    } catch (err) {
      add('error', `invalid JSON — ${err.message}`);
      return;
    }
    entry.blocks.push(parsed);

    for (const root of [].concat(parsed)) {
      const ctx = root['@context'];
      if (!ctx) add('error', 'missing @context');
      else if (!String(JSON.stringify(ctx)).includes('schema.org')) {
        add('error', `@context is not schema.org (${JSON.stringify(ctx)})`);
      }
    }
    for (const node of allNodes(parsed)) {
      entry.types.push(...typesOf(node));
      lintNode(node, add);
    }
  });

  entry.types = [...new Set(entry.types)];
  report.push(entry);
}

// Organization and WebSite belong in the root layout, so a subpage lacking them is not a
// finding. Only their total absence across every page audited is.
const seenTypes = new Set(report.flatMap((e) => e.types));
const missingSitewide = ['Organization', 'WebSite'].filter((t) => !seenTypes.has(t));

if (asJson) {
  console.log(JSON.stringify({ pages: report, missingSitewide }, null, 2));
  process.exit(exitCode);
}

const RANK = { error: 0, warn: 1, info: 2 };
for (const entry of report) {
  console.log(`\n== ${entry.target}`);
  console.log(`   blocks: ${entry.blocks.length}   types: ${entry.types.join(', ') || '(none)'}`);
  const sorted = [...entry.findings].sort((a, b) => RANK[a.level] - RANK[b.level]);
  for (const f of sorted) console.log(`   ${f.level.toUpperCase().padEnd(5)} ${f.msg}`);
  if (sorted.length === 0) console.log('   clean');
}

if (missingSitewide.length) {
  console.log(`\nWARN  no ${missingSitewide.join(' or ')} entity on any page audited — add to the root layout`);
}

process.exit(exitCode);
