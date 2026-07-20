#!/usr/bin/env node
// audit-meta.mjs — per-URL metadata audit with canonical-host integrity checks.
//
// Checks title/description length, canonical presence and host agreement,
// Open Graph and Twitter blocks, robots directives, h1 count, and image alt
// coverage. The canonical-host checks compare declarations against the host
// the request ACTUALLY landed on after redirects — a mismatch splits ranking
// signals even when nothing loops.
//
// LIMITATION: reads server-rendered HTML. Client-injected tags are invisible.
//
// Usage:  node audit-meta.mjs <url|file> [more...] [--base https://host] [--json]
//
//   --base   canonical origin to compare against when auditing local files
//            (for URLs the comparison uses the host actually landed on)
//
// Exit:   0 no errors · 1 an ERROR-level finding · 2 usage error

import { readFile } from 'node:fs/promises';

const UA = 'Mozilla/5.0 (compatible; discoverability/1.0)';

const TITLE_MIN = 30;
const TITLE_MAX = 60;
const DESC_MIN = 70;
const DESC_MAX = 160;

const argv = process.argv.slice(2);
const asJson = argv.includes('--json');
const baseIdx = argv.indexOf('--base');
const base = baseIdx === -1 ? null : argv[baseIdx + 1];
const targets = argv.filter((a, i) => !a.startsWith('--') && !(baseIdx !== -1 && i === baseIdx + 1));

if (targets.length === 0) {
  console.error('Usage: node audit-meta.mjs <url|file> [more...] [--base https://host] [--json]');
  process.exit(2);
}

const ATTR_RE = /([a-zA-Z_:@][\w:.-]*)\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s"'>]+))/g;

function attrs(tag) {
  const out = {};
  for (const m of tag.matchAll(ATTR_RE)) {
    out[m[1].toLowerCase()] = m[2] ?? m[3] ?? m[4] ?? '';
  }
  return out;
}

const decode = (s) =>
  s
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#0?39;|&apos;/g, "'")
    .replace(/\s+/g, ' ')
    .trim();

const hostOf = (u) => {
  try {
    return new URL(u).host;
  } catch {
    return null;
  }
};

function parse(html) {
  const metas = [...html.matchAll(/<meta\s[^>]*>/gi)].map((m) => attrs(m[0]));
  const links = [...html.matchAll(/<link\s[^>]*>/gi)].map((m) => attrs(m[0]));
  const imgs = [...html.matchAll(/<img\s[^>]*>/gi)].map((m) => attrs(m[0]));

  const meta = (name) =>
    metas.find((a) => a.name?.toLowerCase() === name || a.property?.toLowerCase() === name)?.content;

  const titleMatch = html.match(/<title[^>]*>([\s\S]*?)<\/title>/i);

  return {
    title: titleMatch ? decode(titleMatch[1]) : null,
    description: meta('description') ? decode(meta('description')) : null,
    robots: meta('robots') ?? null,
    canonicals: links.filter((a) => a.rel?.toLowerCase() === 'canonical').map((a) => a.href),
    og: {
      title: meta('og:title'),
      description: meta('og:description'),
      image: meta('og:image'),
      url: meta('og:url'),
      type: meta('og:type'),
    },
    twitterCard: meta('twitter:card'),
    h1Count: (html.match(/<h1[\s>]/gi) ?? []).length,
    imgTotal: imgs.length,
    imgNoAlt: imgs.filter((a) => a.alt === undefined).length,
    imgDecorative: imgs.filter((a) => a.alt === '').length,
  };
}

/** "Acme | Pricing | Acme" — a template appending a suffix the page already set. */
function duplicateSegments(title) {
  const parts = title
    .split(/\s[|\-–—·:]\s/)
    .map((p) => p.trim().toLowerCase())
    .filter(Boolean);
  return parts.filter((p, i) => parts.indexOf(p) !== i);
}

function audit(page, finalUrl) {
  const f = [];
  const add = (level, msg) => f.push({ level, msg });
  // For a URL this is the host we actually landed on after redirects; for a
  // local file it comes from --base. Null means host checks are skipped.
  const landedHost = hostOf(finalUrl) ?? hostOf(base);

  if (!page.title) add('error', 'no <title>');
  else {
    const n = page.title.length;
    if (n < TITLE_MIN || n > TITLE_MAX) {
      add('warn', `title is ${n} chars (aim ${TITLE_MIN}–${TITLE_MAX}): "${page.title}"`);
    }
    const dupes = duplicateSegments(page.title);
    if (dupes.length) {
      add('error', `title repeats "${dupes[0]}" — the page title and the template suffix collide`);
    }
  }

  if (!page.description) add('error', 'no meta description');
  else {
    const n = page.description.length;
    if (n < DESC_MIN || n > DESC_MAX) {
      add('warn', `meta description is ${n} chars (aim ${DESC_MIN}–${DESC_MAX})`);
    }
  }

  const noindex = /noindex/i.test(page.robots ?? '');

  if (page.canonicals.length === 0) {
    add('error', 'no <link rel="canonical">');
  } else if (page.canonicals.length > 1) {
    add('error', `${page.canonicals.length} canonical tags — search engines will ignore all of them`);
  } else {
    const c = page.canonicals[0];
    if (!/^https?:\/\//i.test(c)) {
      add('error', `canonical is relative ("${c}") — must be an absolute URL`);
    } else {
      const ch = hostOf(c);
      if (ch && landedHost && ch !== landedHost) {
        add(
          'error',
          `canonical host "${ch}" != landed host "${landedHost}" — ranking signals are split. ` +
            `Align the canonical to the host the site actually serves.`,
        );
      }
      if (noindex) {
        add('error', 'page is noindex AND declares a canonical — contradictory; drop one');
      }
    }
  }

  if (noindex) add('info', `robots: ${page.robots} (intended for session/thank-you pages only)`);

  if (!page.og.title || !page.og.description) add('warn', 'incomplete Open Graph block (title/description)');
  if (!page.og.image) add('warn', 'no og:image — link previews will be blank');
  else if (!/^https?:\/\//i.test(page.og.image)) add('error', `og:image is relative ("${page.og.image}")`);

  if (page.og.url) {
    const oh = hostOf(page.og.url);
    if (oh && landedHost && oh !== landedHost) {
      add('error', `og:url host "${oh}" != landed host "${landedHost}"`);
    }
  } else {
    add('warn', 'no og:url — often inherited wrongly from the root layout');
  }

  if (!page.twitterCard) add('warn', 'no twitter:card');

  if (page.h1Count === 0) add('error', 'no <h1>');
  else if (page.h1Count > 1) add('warn', `${page.h1Count} <h1> elements — use exactly one`);

  if (page.imgNoAlt > 0) {
    add('error', `${page.imgNoAlt}/${page.imgTotal} <img> missing an alt attribute (use alt="" if decorative)`);
  }
  // imgDecorative is carried in --json but not printed: alt="" is correct, not a finding.

  return f;
}

let exitCode = 0;
const report = [];

for (const target of targets) {
  const entry = { target, finalUrl: null, findings: [], page: null };
  try {
    let html;
    if (/^https?:\/\//i.test(target)) {
      const res = await fetch(target, { headers: { 'user-agent': UA }, redirect: 'follow' });
      entry.finalUrl = res.url;
      entry.status = res.status;
      if (!res.ok) {
        entry.findings.push({ level: 'error', msg: `HTTP ${res.status}` });
        exitCode = 1;
        report.push(entry);
        continue;
      }
      html = await res.text();
    } else {
      html = await readFile(target, 'utf8');
      if (!base) {
        entry.findings.push({
          level: 'info',
          msg: 'local file without --base — canonical/og host agreement not checked',
        });
      }
    }
    entry.page = parse(html);
    entry.findings.push(...audit(entry.page, entry.finalUrl));
  } catch (err) {
    entry.findings.push({ level: 'error', msg: `could not read ${target}: ${err.message}` });
  }
  if (entry.findings.some((x) => x.level === 'error')) exitCode = 1;
  report.push(entry);
}

if (asJson) {
  console.log(JSON.stringify(report, null, 2));
  process.exit(exitCode);
}

const RANK = { error: 0, warn: 1, info: 2 };
for (const entry of report) {
  console.log(`\n== ${entry.target}`);
  if (entry.finalUrl && entry.finalUrl !== entry.target) console.log(`   landed: ${entry.finalUrl}`);
  const sorted = [...entry.findings].sort((a, b) => RANK[a.level] - RANK[b.level]);
  for (const f of sorted) console.log(`   ${f.level.toUpperCase().padEnd(5)} ${f.msg}`);
  if (sorted.length === 0) console.log('   clean');
}

process.exit(exitCode);
