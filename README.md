# jseverino-public-site

**Status:** public experiment / migration evaluation  
**Live test URL:** https://static.jseverino.com  
**Production site:** https://jseverino.com  
**Purpose:** compare a static Cloudflare Pages mirror against the current
WordPress-backed site before deciding whether to migrate off WordPress.

This is **not** the canonical source for my website content and it is
**not** the final rebuild. It is a static mirror of the live WordPress
site, published to Cloudflare Pages, so I can test performance,
operational complexity, broken features, SEO behavior, and deployment
workflow before committing to a full migration.

The practical questions this repo answers:

- How much faster and simpler is the site when Cloudflare Pages serves
  static HTML directly?
- Which WordPress-era features break or need replacements?
- Can the current public URL structure, design, SEO surface, and content
  survive a static or Astro-based rebuild?
- What operational burden disappears if WordPress stops being the public
  serving layer?

If the experiment succeeds, the likely next step is a real rebuild where
content comes from my vault and the site is generated directly with Astro.
This mirror is the proving ground, not the destination architecture.

## What's here

- `public/` — the static mirror deployed as-is to Cloudflare Pages.
  Regenerated from the live WordPress source by `scripts/mirror.sh`.
- `public/_headers` and `public/_redirects` — Cloudflare Pages config.
  Preserved across mirror re-runs.
- `scripts/mirror.sh` — wrapper around the `wp-static` tool that can
  regenerate, commit, and push the mirror.

## Current roles

- `jseverino.com` — current WordPress-backed public site.
- `static.jseverino.com` — Cloudflare Pages test mirror from this repo.

Do not treat this repo as the source of truth for content yet. Content
still originates in WordPress, then gets mirrored here for comparison.

## Regenerating the mirror

The mirror logic lives in a reusable CLI:
[`wp-static`](../../tools/wp-static) in the personal tools repo. The
named-site config is in `$TOOLS_HOME/config/wp-static.sh` (gitignored).

```sh
./scripts/mirror.sh
```

This wipes `public/` (backing up `_headers` / `_redirects` first),
re-mirrors `https://jseverino.com/`, cleans up WordPress URL artifacts,
restores the Cloudflare config, and reapplies mirror-only fixes from
`scripts/apply-static-fixes.sh`.

Preview locally:

```sh
python3 -m http.server -d public 8000
```

## Deploying to Cloudflare Pages

This repo is connected to the Cloudflare Pages project behind
`static.jseverino.com`. Deployment is intentionally simple:

```sh
git push origin main
```

Cloudflare Pages builds from the `public/` directory and publishes the
result to `static.jseverino.com`.

For a new Pages project, use:

1. Push to GitHub.
2. Cloudflare dashboard → **Workers & Pages → Create → Pages → Connect to Git**.
3. Select this repo.
4. Build settings:
   - **Framework preset:** None
   - **Build command:** (leave blank)
   - **Build output directory:** `public`
5. Deploy. The first build assigns a `*.pages.dev` URL.

Do not point `jseverino.com` at this project until the migration work is
explicitly ready. For now, the comparison target is
`static.jseverino.com`.

## Speed-test methodology

For an apples-to-apples comparison, test both sites from the same
network with cache disabled. Useful tools:

- WebPageTest (https://www.webpagetest.org) — pick a single test
  location for both runs.
- PageSpeed Insights / Lighthouse — note Mobile and Desktop separately.
- `curl -w '@curl-format.txt' -o /dev/null -s https://...` for raw TTFB.

Run each site three times and median the results; first-hit numbers are
noisy. Cloudflare Pages serves from the edge after the first request, so
expect the second and third runs to be faster than the first.

## Known gaps if you actually migrate

Two pieces of the WordPress site don't carry over to a static mirror:

- **Severino Labs security layer** — anything that runs server-side
  (request filtering, rate limiting, IP blocking) doesn't exist on a
  static host. Cloudflare's WAF + Bot Fight Mode is the static-friendly
  replacement.
- **Contact form** — the WP-handled form stops working. Options:
  - Cloudflare Pages Functions (write a small `functions/contact.js`
    that emails via Resend / a webhook).
  - A third-party static form service (Formspree, Web3Forms, Getform).
  - mailto: link as a fallback.

The simplest migration path: keep WordPress private (admin-only, behind
Cloudflare Access), run `./scripts/mirror.sh` whenever you publish, and
let Pages serve the public site.
