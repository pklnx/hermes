# CLAUDE.md

Guidance for AI agents (and humans) working on this repository.
Auto-loaded by Claude Code at the start of each session.

## Project

A static **single-page landing site** for **`hermes.pklnx.space`**, the private
mail server of `pklnx.space`. The page is a name plate for the host, styled as a
short terminal transcript: ASCII wordmark, one line on the name's origin, a
`whois hermes` fact block, a `cat /etc/motd` line, footer.

The site is private, not commercial: it advertises no services, offers no
sign-up, links only back to `pklnx.space`, and collects nothing. That is a
deliberate scope, not an unfinished state — see "Content & legal rules".

The mail service itself (SMTP/IMAP) runs on the host and has nothing to do with
this repository. **This container serves one HTML page over HTTP and nothing
else** — do not add mail configuration, DNS records or account management here.

## Tech stack & constraints

- **One HTML file with inline CSS. No build step, no framework, no
  dependencies, no JavaScript.** The whole site is `index.html`.
- Do **not** introduce bundlers, npm packages, CSS frameworks, or client-side
  JS unless explicitly requested. Keep it a zero-dependency static page.
- **Hard rule: zero external requests.** No web fonts, no CDNs, no analytics,
  no external images, no `<script>`. That is what lets the page run without a
  consent banner. Concretely:
  - CSS stays inline — in the `<style>` block and in the `style="…"` attributes
    the layout is built from; no `@import`, no `<link rel="stylesheet">`
  - **the typeface is self-hosted.** The original draft loaded JetBrains Mono
    from `fonts.googleapis.com`; that was replaced with a vendored subset when
    the site was containerised, because the Google request hands the visitor's
    IP to Google and is precisely what this rule exists to prevent. **Never put
    the Google Fonts `<link>` back** — see `fonts/README.md` and the section
    "Typeface" below.
  - graphics only as inline SVG or CSS gradient; the favicon is a `data:` URI,
    so the browser never goes looking for `/favicon.ico`
  - the only `http://` in the source is `http://www.w3.org/2000/svg`, the XML
    namespace of the favicon SVG — an identifier, not a URL that gets fetched
  - `<a href="https://pklnx.space">` is fine: a link is navigation, not a
    subresource the page fetches on load
- **Loading the page issues exactly two requests, both same-origin:** the HTML
  and the `woff2`. If a change adds a third, it is wrong.
- CI enforces this. A step in `.github/workflows/docker.yml` fails the build on
  a `<script>`, an `@import`, a `stylesheet`/`preconnect`/`dns-prefetch`/
  `preload` link, an `src="https://…"`, or an absolute `url()` in `index.html`.

## File structure

```
index.html               The entire site (markup + inline CSS)
fonts/*.woff2            Self-hosted JetBrains Mono subset (the only asset)
fonts/OFL.txt            The typeface's license — SIL OFL 1.1, third-party
fonts/subset.sh          Regenerates the subset from an upstream release (by hand)
fonts/check-coverage.py  CI guard: does the subset cover every character on the page?
fonts/README.md          Provenance, credit, why it is vendored and subsetted
Dockerfile               Container image: nginx + the page + the font (no build step)
.dockerignore            Allow-list — only index.html, fonts/*.woff2 and docker/ get in
docker/nginx.conf        nginx config (unprivileged, security headers, IP-free access log)
docker-compose.yml       Runs the container on the server
.github/workflows/docker.yml   Builds, smoke-tests and pushes the image to GHCR (the only deploy)
.github/dependabot.yml         Keeps the workflow's actions current (see "Staying current")
README.md                Human-facing documentation of the same ground
LICENSE                  Proprietary — with a carve-out for the font
```

There is no stylesheet and no `:root` token block: colours are written into the
inline `style` attributes. The palette in use is `#08080a` (ground), `#d9d4c8`
(text), `#f4f1ea` (bright), `#a49f97` (prose), `#7c776f` (labels), `#1c1c20`
(hairline rules) and `#ff4b33` (the single signal colour — prompt, ASCII
wordmark, link hover, cursor). Reuse those values; do not introduce a second
palette, and keep dimmed text at the contrast level it currently has (roughly
6:1 against the ground, well above the 4.5:1 WCAG asks for) — a too-dark grey is
the easy mistake in a layout like this.

The `<style>` block carries only what an inline attribute cannot express:
`@font-face`, `@keyframes`, `a:hover`, the `header, main, footer { min-width: 0 }`
rule and two media queries. Those queries need something to select, which is why
`.cursor` and `.eyebrow` exist — they are hooks, not the start of a class-based
stylesheet. Colours and layout stay in the `style` attributes; keep new rules out
of the block unless a media query or pseudo-class genuinely forces them in.

The prompt line's blinking cursor is a CSS animation (`@keyframes
hermes-blink`), the one piece of motion on the page. Under
`prefers-reduced-motion: reduce` it stops — the `.cursor` class exists precisely
so that the animation can be switched off from the `<style>` block, which an
inline `animation:` would have overridden. It stays visible at full opacity when
stopped; it is part of the prompt, not decoration.

Two auto-minimum traps are already defused, and both bite again if the rule is
removed: grid items default to `min-width: auto` and refuse to shrink below their
content (the header did this at 320 px), and an `fr` track takes `min-content` as
its automatic minimum — hence `minmax(0, 1fr)` plus `overflow-wrap: anywhere` on
the `whois` block, whose unbreakable `hermes.pklnx.space` widened the page the
same way. The narrow-viewport check in "Local preview" is what catches a
regression here.

## Typeface

The page is set in **JetBrains Mono** (SIL OFL 1.1), **self-hosted** — the only
asset the page loads. Full detail in `fonts/README.md`; what matters here:

- One **variable** `woff2`, weight axis 100–800, so a single file covers the 400
  body / 500 prompt / 700 wordmark weights. ~57 kB.
- It is a **subset** (Latin-1, Latin Extended-A, monotonic Greek, General
  Punctuation, arrows). `fonts/check-coverage.py` runs in CI and fails the build
  if a character on the page is not in it — so a copy edit cannot silently
  degrade to the fallback face.
- **`Ἑ` (U+1F19) and `ῆ` (U+1FC6) in `Ἑρμῆς` are not in JetBrains Mono at all**
  — it has monotonic Greek but not the polytonic block. Those two render in the
  platform monospace face and are allow-listed in `check-coverage.py`. This is
  not a subsetting artefact and not fixable by widening the ranges.
- The filename carries a **content hash**. `fonts/subset.sh` regenerates it and
  prints the new `src:` line for `index.html`; nothing regenerates it
  automatically, and the result is committed — the site keeps its "no build
  step" property and the image build stays a pure `COPY`.
- **Code ligatures are disabled page-wide** (`font-variant-ligatures: none` on
  `body`). This is a terminal transcript, not source code, and the ASCII
  wordmark must not be re-shaped.
- Credit is given in `README.md` and `fonts/README.md` although the OFL does not
  require it. Keep it there.

## Content

The page is a terminal transcript:

| Element     | Text                                              |
|-------------|---------------------------------------------------|
| Wordmark    | `hermes` (ASCII art) + `mail server · pklnx.space`|
| Intro       | one line on the name: the messenger of the gods    |
| `host`      | `hermes.pklnx.space`                              |
| `dienst`    | `e-mail (smtp · imap)`                            |
| `herkunft`  | `Ἑρμῆς — bote, wegbereiter, übermittler`           |
| `betreiber` | `pklnx.space`                                     |
| motd        | „was ihm anvertraut wird, kommt an." — access for existing accounts only |
| Footer      | `hermes.pklnx.space` · link back to `pklnx.space` |

The description appears **twice** in the source: as the intro paragraph and in
`<meta name="description">`. Change both.

The page also carries `<meta name="robots" content="noindex">` — the site is
private and is not meant to show up in search results. Don't remove it without
being asked.

The ASCII wordmark sits in a `<pre>` and is whitespace-sensitive: edit it as a
block, never reflow or re-indent it, and keep the surrounding markup from
introducing leading spaces.

## Language conventions

- **Page copy is German** (`<html lang="de">`), lower-case throughout, and uses
  German typographic quotes („…").
- **Code, comments, commit messages, branch names and repository docs are
  English** — same as `pklnx/root`.

## Content & legal rules

The site is **private use only** — no commercial content, no services offered,
no sign-up, no links out except back to `pklnx.space`. That is why it carries
**no Impressum and no Datenschutzerklärung**, and why it needs no consent
banner:

- The imprint duty of **§ 5 DDG** applies to business telemedia. As long as the
  page stays a pure name plate for a privately operated host, it does not apply.
- Consent-free operation rests on the zero-external-requests rule above plus the
  IP-free access log in `docker/nginx.conf` — not on a banner.

**If the page ever gains commercial content, a contact form, account sign-up, a
service description, or links to offerings, both assumptions collapse:** an
Impressum per § 5 DDG and a privacy policy become necessary in the same change.
Don't add such content silently. Note that offering mailboxes to third parties
would make this a service — the current copy deliberately says access is for
existing accounts only.

## Hosting & deployment

**The container image is the only deploy path.** Every push to `main` builds,
smoke-tests and publishes it; there is no Pages deploy and no second path. A
**weekly schedule rebuilds the unchanged commit** so the page keeps serving a
patched nginx even when nobody edits it — see "Staying current" below.

### Without a container

Dropping `index.html` into any web server's document root also works — but then
none of the hardening, headers or the CSP below come with it.

### Docker

```sh
docker compose up -d --build      # or: docker build -t hermes .
curl -I http://127.0.0.1:8081/
```

- **Image:** `nginx:alpine` + `index.html` + `fonts/*.woff2` +
  `docker/nginx.conf`. The `Dockerfile` is pure `COPY`, so the nginx config is
  the only real logic.
- **`.dockerignore` is an allow-list** (`*`, then `!index.html`,
  `!fonts/*.woff2`, `!docker/`). A new asset that is not re-included silently
  never reaches the web root — add it there in the same commit.
- **The base image is deliberately unpinned**, so every rebuild picks up the
  current nginx mainline with its security patches. The price is that a new
  minor can land unannounced — the CI smoke test is what catches it. Pin to a
  minor (`nginx:1.30-alpine`) only if a build ever has to be reproducible.
- **Published to GHCR** by `.github/workflows/docker.yml` on every push to
  `main` (amd64 + arm64), tagged `latest`, `<YYYYMMDD>` and `sha-<commit>`:
  `ghcr.io/pklnx/hermes:latest`. The image name is derived from
  `github.repository`, so it follows a repository rename automatically. The
  server only needs `docker compose pull && docker compose up -d`. **Roll back
  to a date tag, not a `sha-` tag:** a scheduled rebuild builds the same commit
  again and overwrites its `sha-` tag with a newer nginx, so that tag does not
  identify one particular image over time. Pull requests build and smoke-test
  the image but do not push it.
- **Unprivileged by design:** runs as the `nginx` user on port **8080**,
  read-only root filesystem, all capabilities dropped, `no-new-privileges`.
  Port 8080 rather than 80 because non-root may not bind below 1024. Everything
  writable (pid file, temp paths) lives under `/tmp`, and those temp paths must
  stay **one level** below `/tmp` — nginx creates the leaf directory at startup
  but not intermediate parents.
- **Host port 8081.** Inside the container the port is 8080, exactly as in
  `pklnx/root`; the compose file maps it to `127.0.0.1:8081` so both sites can
  live on one host without colliding. Keep the container-side port at 8080 —
  the Dockerfile, the health check and the CI smoke test all assume it.
- **HTTP only, bound to `127.0.0.1`.** A TLS-terminating reverse proxy (Caddy,
  Traefik, nginx) in front forwards to `127.0.0.1:8081`. Without that binding
  the container would sit on the public interface and TLS termination could be
  bypassed. HSTS belongs on the proxy; there is a commented-out
  `Strict-Transport-Security` line in `docker/nginx.conf` for the case where the
  container itself terminates TLS.
- **Privacy:** the `privacy` log format deliberately omits `$remote_addr`. nginx
  always writes the client IP into *error* log entries though (404/403 at
  `error` level) — set `error_log` to `crit` if even those must go.
- **`/healthz`** answers `200 ok` for the `HEALTHCHECK` and uptime probes. A
  separate endpoint keeps health traffic out of the page's access log and out of
  the five-minute caching rule.
- **There is exactly one page.** `location = /` serves `index.html`; everything
  else returns 404, which is also why no explicit dotfile deny is needed.
- Responses carry `expires 5m`. Do not add a `Cache-Control` header next to it —
  `expires` emits one itself and the response would carry two contradictory
  values.
- `add_header` is **not** inherited additively: the moment a `location` block
  sets its own `add_header`, every header from the `server` block is dropped for
  that block. That is why they all live in the `server` block.

### Staying current

The site's own content barely changes; the software in the container does. Three
pieces keep that from rotting, and they only work together:

- **`schedule: '30 4 * * 1'`** in `.github/workflows/docker.yml` rebuilds the
  unchanged commit every Monday (half an hour after `pklnx/root`, so the two do
  not queue up). Because the base tag is unpinned, that picks up nginx patches
  *and* new minors — and the smoke test runs first, so a base image that broke
  something never reaches the registry.
- **`pull: true`** on both build steps. Without it Buildx reuses the cached base
  layer and the schedule accomplishes nothing. Both steps need it: otherwise CI
  would smoke-test a cached base and publish a freshly pulled one.
- **`.github/dependabot.yml`** keeps the workflow's own actions from ageing out.
  There is no `docker` entry on purpose — an unpinned tag has nothing to bump.
  Its side effect matters too: GitHub disables scheduled workflows after 60 days
  without repository activity, and those PRs are what keep the Monday run alive.
  If they ever dry up, one `workflow_dispatch` run resets the clock.

Two consequences worth remembering:

- `org.opencontainers.image.created` is pinned to the **commit** date rather
  than the build time, so an idle rebuild is bit-identical and does not change
  the manifest digest. That is what lets an update watcher (DIUN and friends)
  treat a notification as "the base image actually moved". Don't let
  `metadata-action` stamp the build time back in.
- The rebuild updates the registry, **not the server**. Something on the host
  still has to run `docker compose pull && docker compose up -d` — a systemd
  timer, DIUN, or a manual pull.

### Content Security Policy

```
default-src 'none'; style-src 'unsafe-inline'; img-src data:; font-src 'self';
base-uri 'none'; form-action 'none'; frame-ancestors 'none'
```

This is not decoration but the enforcement of the zero-external-requests rule:
the moment somebody adds an external resource, the browser blocks it instead of
quietly loading it. `style-src 'unsafe-inline'` is required because the CSS sits
inline, in the `<style>` block and in the `style="…"` attributes alike;
`img-src data:` covers the favicon; `font-src 'self'` covers the vendored
typeface. **`font-src` must stay `'self'` and must never gain a hostname** —
that is the directive standing between this page and Google Fonts.

A CSP violation in the browser console means the consent-free operation was
broken — not that the CSP is misconfigured.

## CI

Before publishing, CI checks `index.html` for external subresources and runs
`fonts/check-coverage.py`, then builds the image, starts it with the same
`--read-only --tmpfs /tmp` hardening the compose file uses, and asserts that it
becomes healthy, runs as `nginx` rather than root, serves `index.html`
byte-for-byte, serves the `woff2` byte-for-byte as `font/woff2` with a one-year
`Cache-Control`, answers `/healthz` with 200, sends the CSP (including
`font-src 'self'`) and `X-Content-Type-Options`, and answers everything else —
`/fonts/` and `/fonts/OFL.txt` included — with 404.

**Any change to `index.html`, `fonts/`, `docker/nginx.conf` or the `Dockerfile`
has to keep those assertions true.** The two byte-for-byte diffs in particular
mean the served files and the repo files must not drift, and the font assertion
is what catches a renamed `woff2` that `.dockerignore` no longer lets into the
image.

## Git workflow

- Develop on a feature branch (e.g. `claude/...`), commit, push.
- Land changes through a **PR**; the owner merges. Merging to `main` publishes
  the image to GHCR.

## Local preview

No test suite. Take headless screenshots (Chromium is available) and check
desktop and mobile widths — the ASCII wordmark uses `clamp()` and
`overflow-x: auto`, so a narrow viewport is the case worth looking at.

Assert `document.scrollingElement.scrollWidth === clientWidth` at **320 px**, not
just by eye: both auto-minimum traps above showed up there and nowhere wider.
When it fails, walk the DOM for elements whose `getBoundingClientRect().right`
exceeds the viewport — that names the culprit in one step. Worth a second run
with `prefers-reduced-motion: reduce` emulated, where the cursor's computed
`animationName` has to be `none`.

**Serve the page, don't `file://` it.** The `@font-face` url is root-absolute
(`/fonts/…`), so opening `index.html` from disk loads it without the typeface
and misrepresents the design. `docker compose up -d --build` (or any static
server rooted at the repository) is the honest preview. Worth asserting while
you are there: the page must issue exactly two requests, both same-origin, and
log zero console errors — a CSP violation shows up there and nowhere else.

`docker compose up -d --build` serves the site the way the server will
(http://127.0.0.1:8081) — use it whenever a change could interact with the nginx
config, e.g. new asset types, caching, or anything the CSP has to allow. After
editing `docker/nginx.conf`, syntax-check it with
`nginx -t -c "$PWD/docker/nginx.conf"` if nginx is installed locally.

## License

This is **proprietary, all-rights-reserved** software/content (see `LICENSE`).
It is **not** open source — do not add an open-source license or public-domain
dedication, and do not reuse the code/content elsewhere without the owner's
written permission.

**One carve-out:** the font files under `fonts/` are third-party work under the
SIL Open Font License 1.1 and stay under their own terms — `LICENSE` says so
explicitly. Keep `fonts/OFL.txt` in the repository; that is what satisfies the
OFL's requirement that the license travel with the font.

## Open TODOs

- Keep `README.md` and this file in sync: they document the same decisions, and
  a change to the deployment, the CSP or the content table belongs in both.
- The `LICENSE` copyright year is hardcoded ("2026") — bump it at the turn of
  the year.
- `pklnx/root` carries the same container setup. A fix to the nginx config, the
  workflow or the hardening usually belongs in both repositories.
