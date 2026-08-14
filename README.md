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
- **the typeface is self-hosted, not fetched.** The first draft of this page pulled
  JetBrains Mono from `fonts.googleapis.com`, which hands every visitor's IP address to
  Google — precisely what this rule exists to prevent. The font now lives in `fonts/` and
  is served from this origin; the CSP allows `font-src 'self'` and nothing else. See
  [`fonts/README.md`](fonts/README.md) for provenance, subsetting and regeneration.
- graphics only as inline SVG or CSS gradient; the favicon is a `data:` URI so the browser
  never goes looking for `/favicon.ico`
- no build step, no framework

Loading the page issues exactly **two** requests, both to this origin: the HTML and the
`woff2`.

CI enforces this: a step in `.github/workflows/docker.yml` fails the build if `index.html`
gains a `<script>`, an `@import`, a stylesheet/preconnect/preload `<link>`, an
`src="https://…"`, or an absolute `url()` in CSS. Anchor links
(`<a href="https://pklnx.space">`) are navigation, not subresources, and stay allowed; so
is the relative `url()` of the local font.

The only `http://` in the source is `http://www.w3.org/2000/svg`, the XML namespace of the
favicon SVG. That is an identifier, not a URL that gets fetched.

## Content

The page is a terminal transcript in German: an ASCII wordmark, a one-line explanation of
the name, a `whois hermes` block of host facts, and a `cat /etc/motd` line.

| Element     | Text                                             |
|-------------|--------------------------------------------------|
| Wordmark    | `hermes` (ASCII art) + `mail server · pklnx.space`|
| `host`      | `hermes.pklnx.space`                             |
| `dienst`    | `e-mail (smtp · imap)`                           |
| `herkunft`  | `Ἑρμῆς — bote, wegbereiter, übermittler`          |
| `betreiber` | `pklnx.space`                                    |
| Footer      | `hermes.pklnx.space` · link back to `pklnx.space`|

The page copy is German (`<html lang="de">`); the repository's docs, comments and commit
messages are English. `<meta name="description">` repeats the one-line description — change
both together.

## Design

Dark, reduced, terminal-flavoured: near-black `#08080a` ground, bone-white `#d9d4c8` text,
a single signal colour `#ff4b33` for the prompt, the ASCII wordmark and link hovers. The
prompt line carries a blinking block cursor (`@keyframes hermes-blink`); the fact blocks
sit behind a hairline rule in `#1c1c20`.

Set in **JetBrains Mono** (see [Credits](#credits)), self-hosted, one variable file for
every weight. Code ligatures are switched off page-wide — this is a terminal transcript,
not source code, and the ASCII wordmark has no business being re-shaped by them.

Layout and colours live in inline `style` attributes rather than in classes — the page is
one screen and one file, and the CSP allows inline styles for exactly that reason. Keep new
values consistent with the ones already in use instead of introducing a second palette.

## Deployment

Two options. Both serve the same file.

### Without a container

Drop `index.html` **and the `fonts/` directory** into the document root of any web server —
the `@font-face` url is root-absolute (`/fonts/…`), so the font has to sit at
`<docroot>/fonts/`. That is all — but then none of the hardening, headers or the CSP below
come with it, and the font is served without the one-year cache.

### As a container

The image is an `nginx:alpine` with `index.html`, `fonts/*.woff2` and `docker/nginx.conf`
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
`docker` entry on purpose — an unpinned tag has nothing to bump. Those PRs also keep the
schedule alive: GitHub disables scheduled workflows after 60 days without repository
activity. A manual run (`workflow_dispatch`) resets that clock if it ever comes to it.

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
- **No client IPs in the access log.** `docker/nginx.conf` uses a `privacy` log format that
  records everything except `$remote_addr`. The error log is the exception: nginx always
  stamps the client IP into it and offers no way to format that away.

Before publishing, CI checks that `index.html` pulls in nothing external and that the font
covers every character on the page, then builds the image, starts it with the same
`--read-only --tmpfs /tmp` hardening the compose file uses, and checks that it becomes
healthy, runs as `nginx` rather than root, serves `index.html` byte-for-byte, serves the
`woff2` byte-for-byte as `font/woff2` with a one-year cache, answers `/healthz` with a 200,
sends the CSP, and answers everything else — `/fonts/` and `/fonts/OFL.txt` included — with
a 404. Pull requests run the same build and smoke test but push nothing, so a broken image
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

The page is set in **[JetBrains Mono](https://www.jetbrains.com/lp/mono/)** by
**JetBrains**, licensed under the SIL Open Font License 1.1 — free to use, commercially and
otherwise, with no attribution required. It is credited here anyway, because the typeface
is what makes the terminal look on this page work. Full provenance, license text and the
regeneration procedure: [`fonts/README.md`](fonts/README.md).

## License

The site itself is proprietary — see [`LICENSE`](LICENSE). Copyright (c) 2026 Patrick
Klein, all rights reserved. Nothing in this repository may be used, copied, or
redistributed without prior written permission.

**Exception:** the font files under `fonts/` are not covered by that. JetBrains Mono is
third-party work under the SIL Open Font License 1.1 ([`fonts/OFL.txt`](fonts/OFL.txt)) and
stays under its own terms.
