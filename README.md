# hermes.pklnx.space

Static landing page for `hermes`, the private mail server of `pklnx.space`. The page is a
name plate for the host — it advertises nothing, links only back to `pklnx.space`, and
offers no way to sign up. Mail itself (SMTP/IMAP) is served by the host, not by this
container.

The entire site is a single file: `index.html`.

## Hard constraint: zero external requests

The page loads **nothing** from the outside — no web fonts, no CDNs, no analytics, no
external images. That is what lets it run without a consent banner. In practice, for every
change to this file:

- CSS stays inline (in `<style>` and in the `style="…"` attributes the layout is built
  from); no `@import`, no `<link rel="stylesheet">`
- no JavaScript, no `<script>` tags
- **the typefaces are self-hosted, not fetched.** IBM Plex Mono and IBM Plex Sans live in
  `fonts/` and are served from this origin; the CSP allows `font-src 'self'` and nothing
  else. A `fonts.googleapis.com` link would hand every visitor's IP address to Google —
  precisely what this rule exists to prevent. See [`fonts/README.md`](fonts/README.md)
  for provenance and regeneration.
- graphics only as inline SVG or CSS gradient; the favicon is a `data:` URI so the browser
  never goes looking for `/favicon.ico`
- no build step, no framework

Loading the page issues exactly **four** requests, all to this origin: the HTML and the
three `woff2` files (preloaded from `<head>`).

CI enforces this: a step in `.github/workflows/docker.yml` fails the build if `index.html`
gains a `<script>`, an `@import`, a stylesheet/preconnect/dns-prefetch `<link>`, a `<link>`
pointing off-origin, an absolute `src=`, or an absolute `url()` in CSS; the smoke test also
fails on a Google Fonts host anywhere in the file. Anchor links
(`<a href="https://pklnx.space">`) are navigation, not subresources, and stay allowed; so
are the same-origin font preloads and the root-relative `url()`s of the local fonts.

The only `http://` in the source is `http://www.w3.org/2000/svg`, the XML namespace of the
favicon SVG. That is an identifier, not a URL that gets fetched.

## Content

The page is a terminal transcript in German: the `hermes` wordmark, a one-line explanation of
the name, a `whois hermes` block of host facts, a `whois -a hermes` block naming the person
responsible for mail dispatch, and a `cat /etc/motd` line.

| Element     | Text                                             |
|-------------|--------------------------------------------------|
| Header      | logo mark (links to `pklnx.space`) · `Mail-Server · pklnx.space` |
| Wordmark    | `hermes` in the space-bar bracket (inline SVG)   |
| `host`      | `hermes.pklnx.space`                             |
| `dienst`    | `E-Mail (SMTP · IMAP)`                           |
| `herkunft`  | `Griech. Hermes — Bote, Wegbereiter, Übermittler` |
| `betreiber` | `pklnx.space`                                    |
| `name`      | responsible person for mail dispatch              |
| `anschrift` | postal address                                    |
| `e-mail`    | contact address (`mailto:` link)                  |
| `telefon`   | contact phone (`tel:` link)                       |
| Footer      | `hermes.pklnx.space` · arrow icon + link back to `pklnx.space` |

The `whois -a hermes` block exists so that the PTR domain of the mail server's outbound IP
resolves to a page that shows the responsible person's direct contact details on load — not
just a link elsewhere. Large mail providers' postmaster teams check for this before lifting a
reputation block on a new sender IP.

The page copy is German (`<html lang="de">`) with normal German capitalisation, as the
design system asks; only the `whois` field labels and host names stay lower-case, as
command output. The repository's docs, comments and commit messages are English. `<meta name="description">` repeats the one-line description — change
both together.

## Design

The page follows the **[pklnx design system](https://github.com/pklnx/design-system)**
(IBM Carbon v11, G100 dark theme, Purple as the one accent), the same as
[`pklnx/root`](https://github.com/pklnx/root): a hairline-ruled header with the logo mark
(space-bar bracket + star), the wordmark set large, and the fact blocks under `$` prompts
against a vertical rule. It takes the look only (tokens, type, spacing, logo, prompt
style): no Carbon CSS, no components, no script, and none of the design system's business
voice.

- **Colours and spacing** are Carbon tokens under their Carbon names and G100 values,
  declared once as `:root` variables in `index.html`: `--background #161616`,
  `--border-subtle-00 #393939`, `--text-primary #f4f4f4`, `--text-secondary #c6c6c6`,
  `--link-primary #be95ff`, `--link-primary-hover #d4bbff`, `--focus #ffffff`, the brand's
  `--star #a56eff`, plus `--spacing-*` and the `--font-*` stacks. `--star` is the only
  accent and appears in exactly two places, the star in the mark and the `$` sigils; links
  use `--link-primary`. Every dimmed text is `--text-secondary`, 10.6:1 against the
  background.
- **Type:** Carbon's productive scale. IBM Plex Mono for command output (`whois` labels and
  values in `code-02`, footer in `code-01`) and the prompts (the design system's `prompt`
  style, Plex Mono SemiBold 28 px, 20 px below 40 rem); IBM Plex Sans for language (eyebrow
  `label-01`, intro and motd `body-02`).
- **Wordmark:** `hermes` in IBM Plex Mono Bold inside the space-bar bracket of the
  pklnx.space logo, as inline SVG paths, so it renders the same with or without the
  webfont. It is built exactly like the design system's wordmark (`scripts/build_logo.py`
  there): 60-unit advance, bracket 8.5 units thick and 34 units outside the glyph bounds,
  bracket depth taken from the pklnx wordmark so both stand at the same height, viewBox
  `-27.5 -72 414.9 112.5`. Its CSS clamp is root's scaled by 414.9/715.4. Generate new paths
  from IBM Plex Mono rather than drawing them by hand.
- Square corners, no shadows, Carbon focus (2 px white inside on the mark, 1 px on text
  links), Carbon icons filled in `currentColor`. **Nothing animates.**
- Below 40 rem the header's eyebrow is dropped; below 30 rem the `whois` labels stack above
  their values. `header, main, footer { min-width: 0 }` and the `minmax(0, 1fr)` value
  column keep the page from scrolling sideways at 320 px.

## Deployment

Two options. Both serve the same file.

### Without a container

Drop `index.html` **and the `fonts/` directory** into the document root of any web server —
the `@font-face` urls are root-absolute (`/fonts/…`), so the fonts have to sit at
`<docroot>/fonts/`. That is all — but then none of the hardening, headers or the CSP below
come with it.

### As a container

The image is an `nginx:alpine` with `index.html`, `fonts/` (the `woff2` files and their
`OFL-IBMPlex.txt` licence) and `docker/nginx.conf`
baked in — no build step, no runtime, no dependencies. It serves **HTTP on port 8080 only**; TLS is
handled by the reverse proxy in front. The base image is intentionally unpinned, so every
rebuild picks up the current nginx (mainline) with its security patches. A new minor can
therefore land unannounced — the smoke test below is what catches it. If a build ever needs
to be reproducible, pin the tag in the `Dockerfile` to a minor such as `nginx:1.30-alpine`.

```
docker compose up -d --build
```

Or without compose:

```
docker build -t hermes .
docker run -d --name hermes --read-only --tmpfs /tmp -p 127.0.0.1:8081:8080 hermes
```

Prebuilt images are published on every push to the default branch as
`ghcr.io/pklnx/hermes:latest` (amd64 and arm64), built by `.github/workflows/docker.yml`:

```
docker pull ghcr.io/pklnx/hermes:latest
```

**Host port 8081.** Inside the container nginx always listens on 8080, same as
[`pklnx/root`](https://github.com/pklnx/root). If both sites ever run on one host, two
containers cannot share host port 8080 — so this one is mapped to `127.0.0.1:8081`. Change
it in `docker-compose.yml` if that clashes with something else.

### Keeping the container current

The page changes rarely; nginx and the Alpine packages inside the image do not.
The same workflow therefore also runs **every Monday at 04:30 UTC** and rebuilds the
unchanged commit. The image is pure `COPY` on top of an unpinned `nginx:alpine`, so that
rebuild picks up patches and new minors alike — with the smoke test in front of it, so a
base image that broke something never reaches the registry. `pull: true` on the build steps
is what makes this work at all; without it Buildx would reuse the cached base layer.

`.github/dependabot.yml` keeps the workflow's own actions from ageing out. It has no
`docker` entry on purpose — an unpinned tag has nothing to bump. GitHub disables scheduled
workflows after 60 days without a commit; the `keepalive` job in the same workflow
re-enables it through the API on every scheduled or manual run, which resets that clock.

Two things to know when operating this:

- **Roll back to a date tag, not a `sha-` tag.** Images are tagged `latest`, `<YYYYMMDD>`
  and `sha-<commit>`; a scheduled rebuild builds the same commit again and overwrites its
  `sha-` tag with a newer nginx, so only the date tag identifies one particular image over
  time.
- **The rebuild updates the registry, not the server.** Something on the host still has to
  `docker compose pull && docker compose up -d` — a systemd timer, an update watcher such
  as DIUN, or a manual pull. An idle rebuild is bit-identical on purpose
  (`org.opencontainers.image.created` is pinned to the commit date), so such a watcher only
  fires when the base image really moved.

A few decisions that need explaining in operation:

- **Port 8080, not 80.** The container runs as non-root (`USER nginx`), and unprivileged
  processes may not bind ports below 1024. Everything writable (pid, temp files) therefore
  lives under `/tmp`.
- **Bound to `127.0.0.1`.** The container is reachable on the loopback interface only; the
  reverse proxy on the host forwards to it. Without that binding it would sit on the public
  interface and TLS termination could be bypassed.
- **`read_only: true`** in the compose file, with a `tmpfs` for `/tmp`. Nothing else is
  written at runtime — the nginx pid file and all temp paths point below `/tmp`. If that
  ever causes trouble, it is the first line to drop.
- **Health check against `/healthz`.** A separate endpoint keeps health traffic out of the
  page's access log, and the probe stays independent of the caching rule on `/`.
- **Fonts under `/fonts/`, cached for 30 days.** That location serves only `.woff2` and
  `.txt` (the OFL licences, which the licence requires to travel with the fonts) with
  explicit MIME types; `fonts/README.md` stays out of the image.
- **No client IPs in the access log.** `docker/nginx.conf` uses a `privacy` log format that
  records everything except `$remote_addr`. The error log is the exception: nginx always
  stamps the client IP into it and offers no way to format that away.

Before publishing, CI checks that `index.html` pulls in nothing external, then builds the
image, starts it with the same `--read-only --tmpfs /tmp` hardening the compose file uses,
and checks that it becomes healthy, runs as `nginx` rather than root, serves `index.html`
byte-for-byte, serves every `woff2` the page references byte-for-byte as `font/woff2`
plus the `OFL-IBMPlex.txt` licence, answers `/healthz` with a 200, sends the CSP, carries no
Google Fonts host, and answers everything else with a 404. Pull requests run the same build and smoke test but push nothing, so a broken image
never reaches the registry.

### Reverse proxy examples

nginx on the host:

```nginx
location / {
    proxy_pass http://127.0.0.1:8081;
    proxy_set_header Host              $host;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

Caddy:

```
hermes.pklnx.space {
    reverse_proxy 127.0.0.1:8081
}
```

## Content Security Policy

`docker/nginx.conf` sets a CSP that pins down what the page already does:

```
default-src 'none'; style-src 'unsafe-inline'; img-src data:; font-src 'self';
base-uri 'none'; form-action 'none'; frame-ancestors 'none'
```

This is not decoration but the enforcement of the rule at the top: the moment somebody adds
an external resource, the browser blocks it instead of quietly loading it. `style-src
'unsafe-inline'` is required because the CSS sits inline, in the `<style>` block and in the
`style="…"` attributes alike; `img-src data:` covers the favicon; `font-src 'self'` covers
the vendored typeface — **`'self'` and never a hostname**, which is the line that stops
Google Fonts from creeping back in. Scripts are forbidden entirely, inline ones too.

If you extend the page and see a CSP violation in the browser console, you broke the
consent-free operation, you did not misconfigure the CSP.

## Credits

The page is set in **[IBM Plex Mono and IBM Plex Sans](https://github.com/IBM/plex)**,
© 2017 IBM Corp. with Reserved Font Name "Plex", under the SIL Open Font License 1.1. Full
provenance, licence texts and the regeneration procedure:
[`fonts/README.md`](fonts/README.md).

## License

The site itself is proprietary — see [`LICENSE`](LICENSE). Copyright (c) 2026 Patrick
Klein, all rights reserved. Nothing in this repository may be used, copied, or
redistributed without prior written permission.

**Exception:** the font files under `fonts/` are not covered by that. IBM Plex Mono and
IBM Plex Sans are third-party work under the SIL Open Font License 1.1
([`fonts/OFL-IBMPlex.txt`](fonts/OFL-IBMPlex.txt)) and stay under their own terms.
