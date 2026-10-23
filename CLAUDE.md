# CLAUDE.md

Guidance for AI agents (and humans) working on this repository.
Auto-loaded by Claude Code at the start of each session.

## Project

A static **single-page landing site** for **`hermes.pklnx.space`**, the private
mail server of `pklnx.space`. The page is a name plate for the host in the
pklnx.space brand, styled as a short terminal transcript: logo mark, the
`hermes` wordmark in the space-bar bracket, one line on the name's origin, the
`whois hermes` and `whois -a hermes` fact blocks, a `cat /etc/motd` line, footer.

The site is private, not commercial: it advertises no services, offers no
sign-up, links only back to `pklnx.space`, and collects nothing. That is a
deliberate scope, not an unfinished state — see "Content & legal rules".

The mail service itself (SMTP/IMAP) runs on the host and has nothing to do with
this repository. **This container serves one HTML page over HTTP and nothing
else** — do not add mail configuration, DNS records or account management here.

## Tech stack & constraints

- **One HTML file with inline CSS. No build step, no framework, no
  dependencies, no JavaScript.** The site is `index.html` plus the webfonts in
  `fonts/`.
- Do **not** introduce bundlers, npm packages, CSS frameworks, or client-side
  JS unless explicitly requested. Keep it a zero-dependency static page.
- **Hard rule: zero external requests.** No third-party fonts, no CDNs, no
  analytics, no external images, no `<script>`. That is what lets the page run
  without a consent banner. Concretely:
  - CSS stays inline in `<style>` — no `@import`, no `<link rel="stylesheet">`
  - two typefaces, IBM Plex Mono and IBM Plex Sans, **self-hosted out of
    `fonts/`** (see "Typeface"), each with Carbon's system stack behind it as
    fallback. **Never a `fonts.googleapis.com` link** — it hands the visitor's
    IP to Google, which is precisely what this rule exists to prevent, and CI
    fails if one appears (the design system's README suggests loading from
    Google Fonts; for this repo that does not apply).
  - graphics only as inline SVG or CSS gradient; the favicon is a `data:` URI,
    so the browser never goes looking for `/favicon.ico`
  - the only `http://` in the source is `http://www.w3.org/2000/svg`, the XML
    namespace of the favicon SVG — an identifier, not a URL that gets fetched
  - `<a href="https://pklnx.space">` is fine: a link is navigation, not a
    subresource the page fetches on load
- **Loading the page issues exactly four requests, all same-origin:** the HTML
  and the three preloaded `woff2` files. If a change adds a fifth, it is wrong.
- CI enforces this. A step in `.github/workflows/docker.yml` fails the build on
  a `<script>`, an `@import`, a `stylesheet`/`preconnect`/`dns-prefetch` link,
  a `<link>` pointing off-origin, an absolute `src=`, or an absolute `url()` in
  `index.html`; the smoke test additionally fails on a Google Fonts host
  anywhere in the file, comments included.

## File structure

```
index.html               The entire site (markup + inline CSS)
fonts/*.woff2            Self-hosted IBM Plex Mono 400/600 + IBM Plex Sans 400
fonts/OFL-IBMPlex.txt    The licence for both — SIL OFL 1.1, third-party, served with the fonts
fonts/README.md          Provenance, credit, how the files were produced
Dockerfile               Container image: nginx + the page + fonts/ (no build step)
.dockerignore            Allow-list — only index.html, fonts/ (minus its README) and docker/ get in
docker/nginx.conf        nginx config (unprivileged, security headers, IP-free access log)
docker-compose.yml       Runs the container on the server
.github/workflows/docker.yml   Builds, smoke-tests and pushes the image to GHCR (the only deploy)
.github/dependabot.yml         Keeps the workflow's actions current (see "Staying current")
README.md                Human-facing documentation of the same ground
LICENSE                  Proprietary — with a carve-out for the fonts
```

**Same brand, same infrastructure as `pklnx/root`.** Design tokens, fonts,
`docker/nginx.conf`, `Dockerfile`, `.dockerignore` and the workflow were taken
over from there; only names, the host port and the cron minute differ. Keep it
that way — a fix to one usually belongs in both.

**The brand is the pklnx design system** (`pklnx/design-system`): IBM Carbon v11,
G100 (dark) theme, Purple as the one accent, IBM Plex throughout. The page takes
its *look* from there (tokens, type scale, spacing, logo, the prompt style) and
nothing else: no Carbon CSS, no components, no JS. The design system's voice for
business copy (first person, „Leistungen", „Sie" towards clients) does not apply
to a private name plate (see "Content & legal rules").

Design tokens live in the `:root` CSS variables in `index.html`, **under their
Carbon names and G100 values** — the same set `pklnx/root` uses, minus its row
hover: `--background #161616`, `--border-subtle-00 #393939` (every rule),
`--text-primary #f4f4f4`, `--text-secondary #c6c6c6`, `--link-primary #be95ff`,
`--link-primary-hover #d4bbff`, `--focus #ffffff`, the brand token
`--star #a56eff`, Carbon's `--spacing-*` steps and `--font-mono`/`--font-sans`.
Reuse those variables; don't hardcode colours, and take any further token from
root or the design system's `project/tokens.css` (same name, same value) rather
than inventing one. `--star` is the only accent and appears in exactly two
places, the star in the mark and the `$` sigils; links use `--link-primary`.
`--text-secondary` (10.6:1) is the only dimmed token and carries the 12 px
text; Carbon's fainter `text-helper` is deliberately left out.

Type follows Carbon's productive scale, set by hand (each rule names its style
in a comment): `whois` labels and values `code-02`, footer `code-01`, eyebrow
`label-01`, intro and motd `body-02`. The prompts are the design system's
`prompt` style (Plex Mono SemiBold 28 px), its 20 px step below 40 rem, where
`$ whois -a hermes` would otherwise fill the 320 px line. Square corners, no
shadows; focus is Carbon's: 2 px `--focus` inside on the mark, 1 px on text
links. Icons are Carbon icons (32 grid, filled, `currentColor`) at 16 px.

**The logo is inline SVG, not text.** The header mark (bracket + star) is the
design system's `pklnx-mark-dark.svg` and links back to `pklnx.space`. The
wordmark is `hermes` in IBM Plex Mono Bold inside the space-bar bracket,
generated exactly like the design system's wordmark (`scripts/build_logo.py`
there: 100-unit font size, so a 60-unit advance; bracket 8.5 units thick, 34
units outside the glyph bounds, tips at y = −6). `hermes` has no descender, so
the bracket takes the pklnx wordmark's depth (inner edge y = 32, outer 40.5) and
both marks stand at the same height. viewBox `-27.5 -72 414.9 112.5`; the CSS
clamp is root's scaled by 414.9/715.4. Fills come only from the `.ink` and
`.star` classes. Do not retype the wordmark as live text or redraw the paths by
hand — regenerate them from `@ibm/plex-mono` 2.5.0 (`fonts/complete/woff2/
IBMPlexMono-Bold.woff2`, the file the design system builds from) with fontTools.
The favicon is the design system's `pklnx-favicon.svg` as a `data:` URI.

Two auto-minimum traps are defused, and both bite again if the rule is removed:
grid items default to `min-width: auto` (hence `header, main, footer
{ min-width: 0 }`), and an `fr` track takes `min-content` as its automatic
minimum — hence `minmax(0, 1fr)` plus `overflow-wrap: anywhere` on the `whois`
blocks, whose unbreakable `hermes.pklnx.space` widens the page otherwise. Below
40 rem the eyebrow is hidden; below 30 rem the `whois` labels stack above their
values. **Nothing on the page animates** — the blinking caret is gone with the
JetBrains Mono version; it and the Space Mono version in orange are reachable
through the git history.

## Typeface

The page is set in **IBM Plex Mono** (400 for `whois` labels and values and the
footer; 600 for the `$` prompts) and **IBM Plex Sans** (400 for the eyebrow and
the two prose lines: intro and motd), both self-hosted. Full detail in
`fonts/README.md`; what matters here:

- **IBM Plex is not subset by us:** its Reserved Font Name "Plex" means a
  modified file could not keep the name, so the page ships IBM's own `-Latin1`
  split files, unmodified (~18 KB per Mono weight, ~21 KB for Sans).
- **No Greek.** None of the files carries it, which is why the `herkunft` row
  reads `Griech. Hermes` instead of the original `Ἑρμῆς`. The same goes for
  anything else outside Latin-1 plus common punctuation: check a copy edit
  against the fonts' cmaps rather than letting it fall back to the system face.
  Arrows are Carbon icons as inline SVG, not glyphs.
- File names carry no version; `/fonts/` is cached for 30 days. A font update
  therefore takes up to a month to reach a returning visitor — harmless.
- Credit is given in the `@font-face` comments, `README.md` and
  `fonts/README.md`. Both families ship the same licence text, so one file,
  `fonts/OFL-IBMPlex.txt`, goes into the image and is served under `/fonts/`,
  because the OFL requires the licence to travel with each font — don't drop it
  to save a few kilobytes.

## Content

The page is a terminal transcript:

| Element     | Text                                              |
|-------------|---------------------------------------------------|
| Header      | logo mark (links to `pklnx.space`) · eyebrow `Mail-Server · pklnx.space` |
| Wordmark    | `hermes` in the space-bar bracket (inline SVG)    |
| Intro       | one line on the name: the messenger of the gods    |
| `host`      | `hermes.pklnx.space`                              |
| `dienst`    | `E-Mail (SMTP · IMAP)`                            |
| `herkunft`  | `Griech. Hermes — Bote, Wegbereiter, Übermittler`  |
| `betreiber` | `pklnx.space`                                     |
| `name`      | `Patrick Klein` — person responsible for mail dispatch |
| `anschrift` | postal address (deliverable, per Telekom FAQ 4.1)  |
| `e-mail`    | `postmaster@pklnx.space`, as `mailto:` link         |
| `telefon`   | contact phone number, as `tel:` link                |
| motd        | „Was ihm anvertraut wird, kommt an." — access for existing accounts only |
| Footer      | `hermes.pklnx.space` · arrow icon + link back to `pklnx.space` |

The `whois -a hermes` block (`name`/`anschrift`/`e-mail`/`telefon`) exists so the PTR domain
of the mail server's outbound IP resolves to a page showing the responsible person's direct
contact details on load, not just a link elsewhere — some large mail providers require this
before lifting a reputation block on a sender IP. It reuses the `whois hermes` block's `<dl>`
grid and colour conventions; see "Content & legal rules" below for why this does not turn
the site into a business telemedium requiring an Impressum.

The description appears **three times** in the source: as the header eyebrow,
as the intro paragraph and in `<meta name="description">`. Change all three.

The page also carries `<meta name="robots" content="noindex">` — the site is
private and is not meant to show up in search results. Don't remove it without
being asked.

## Language conventions

- **Page copy is German** (`<html lang="de">`) with normal German
  capitalisation, as the design system asks, and uses German typographic quotes
  („…"). Only the `whois` field labels (`host`, `dienst`, …) and host names stay
  lower-case: they are command output, not prose.
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

**The `whois -a hermes` contact block (name, postal address, e-mail, phone) is
not such content.** It exists solely because Deutsche Telekom's postmaster
team (and other large providers) require the mail server's PTR domain to show
the responsible person's direct contact details before lifting an IP
reputation block — an administrative/abuse contact, the same category as a
RIPE `abuse-mailbox:` field, not a service offering. It doesn't collect
anything from visitors, so it needs no privacy notice either: a
Datenschutzerklärung is about informing visitors what the site does with
*their* data, and this page still does nothing with visitor data (see
"Hard rule: zero external requests" and the IP-free access log). If this
block ever grows into something that solicits or processes visitor data,
revisit this assumption.

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

- **Image:** `nginx:alpine` + `index.html` + `fonts/` + `docker/nginx.conf`.
  The `Dockerfile` is pure `COPY`, so the nginx config is the only real logic.
- **`.dockerignore` is an allow-list** (`*`, then `!index.html`, `!fonts/`
  minus `fonts/README.md`, `!docker/`). A new asset that is not re-included
  silently never reaches the web root — add it there in the same commit.
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
- **There is exactly one page.** `location = /` serves `index.html`, `^~ /fonts/`
  serves the webfonts and their `OFL-IBMPlex.txt` licence, everything else returns
  404 — which is also why no explicit dotfile deny is needed. The fonts block
  spells its MIME types out in a `types` block, so a base image without `woff2`
  in `mime.types` cannot turn the font into an octet-stream; note that a
  `types` block *replaces* the inherited table, so nothing but `.woff2` and
  `.txt` belongs in that directory.
- Responses carry `expires 5m`, the fonts `expires 30d`. Do not add a `Cache-Control` header next to it —
  `expires` emits one itself and the response would carry two contradictory
  values.
- `add_header` is **not** inherited additively: the moment a `location` block
  sets its own `add_header`, every header from the `server` block is dropped for
  that block. That is why they all live in the `server` block.

### Staying current

The site's own content barely changes; the software in the container does. Four
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
- **The `keepalive` job** in `docker.yml` stops GitHub from disabling the
  schedule after 60 days without a commit. Unmerged Dependabot PRs do not
  count, so it re-enables the workflow through the API on every scheduled or
  manual run, which resets that clock. It needs `actions: write`, granted to
  that job only. If the schedule ever is disabled anyway,
  *Actions → the workflow → Enable workflow* revives it.

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
inline; `img-src data:` covers the favicon; `font-src 'self'` covers the
self-hosted typefaces. **`font-src` must stay `'self'` and must never gain a hostname** —
that is the directive standing between this page and Google Fonts.

A CSP violation in the browser console means the consent-free operation was
broken — not that the CSP is misconfigured.

## CI

Before publishing, CI checks `index.html` for external subresources, then
builds the image, starts it with the same `--read-only --tmpfs /tmp` hardening
the compose file uses, and asserts that it becomes healthy, runs as `nginx`
rather than root, serves `index.html` byte-for-byte, delivers every
`/fonts/*.woff2` the page references byte-for-byte as `font/woff2` plus the
`OFL-IBMPlex.txt` licence, answers `/healthz` with 200, sends the CSP (including
`font-src 'self'`) and `X-Content-Type-Options`, carries no Google Fonts host,
and answers everything else with 404.

**Any change to `index.html`, `fonts/`, `docker/nginx.conf` or the `Dockerfile`
has to keep those assertions true.** The byte-for-byte diffs in particular mean
the served files and the repo files must not drift.

## Git workflow

- Develop on a feature branch (e.g. `claude/...`), commit, push.
- Land changes through a **PR**; the owner merges. Merging to `main` publishes
  the image to GHCR.

## Local preview

No test suite. Take headless screenshots (Chromium is available) and check
desktop and mobile widths — the wordmark scales with `clamp()` and the
`whois` blocks change layout below 30 rem, so a narrow viewport is the case
worth looking at.

Assert `document.scrollingElement.scrollWidth === clientWidth` at **320 px**, not
just by eye: both auto-minimum traps above showed up there and nowhere wider.
When it fails, walk the DOM for elements whose `getBoundingClientRect().right`
exceeds the viewport — that names the culprit in one step.

**Serve the page, don't `file://` it.** The `@font-face` urls are root-absolute
(`/fonts/…`), so opening `index.html` from disk loads it without the typefaces
and misrepresents the design (`python3 -m http.server` in the repository root
is enough). Headless Chromium's `--window-size` will not go below ~500 px;
drive a real 320 px viewport through Playwright. `docker compose up -d --build` (or any static
server rooted at the repository) is the honest preview. Worth asserting while
you are there: the page must issue exactly four requests, all same-origin, and
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

**One carve-out:** the font files under `fonts/` (IBM Plex Mono, IBM Plex Sans)
are third-party work under the SIL Open Font License 1.1 and stay under their own
terms — `LICENSE` says so explicitly. Keep `fonts/OFL-IBMPlex.txt` in the
repository and in the image; that is what
satisfies the OFL's requirement that the licence travel with each font.

## Open TODOs

- Keep `README.md` and this file in sync: they document the same decisions, and
  a change to the deployment, the CSP or the content table belongs in both.
- The `LICENSE` copyright year is hardcoded ("2026") — bump it at the turn of
  the year.
- `pklnx/root` carries the same brand and container setup. A fix to the tokens,
  the fonts, the nginx config, the workflow or the hardening usually belongs in
  both repositories.
