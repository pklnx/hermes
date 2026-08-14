# hermes.pklnx.space — static single-page landing site for the mail server.
#
# The site is a single HTML file with inline CSS and no build step, so the image
# is nothing but nginx plus that file. Build and run:
#
#   docker build -t hermes .
#   docker run --rm --read-only --tmpfs /tmp -p 8080:8080 hermes
#
# The base image is deliberately unpinned: every rebuild picks up the current
# alpine image, so security patches arrive without anyone having to notice them.
# The price is that a new nginx minor can land unannounced — which is what the
# smoke test in .github/workflows/docker.yml is there to catch before the image
# reaches the registry. Pin to a minor (nginx:1.30-alpine) if a build ever has
# to be reproducible.
FROM nginx:alpine

LABEL org.opencontainers.image.title="hermes" \
      org.opencontainers.image.description="Static landing page of hermes — private mail server of pklnx.space" \
      org.opencontainers.image.url="https://hermes.pklnx.space/" \
      org.opencontainers.image.licenses="LicenseRef-Proprietary"

COPY docker/nginx.conf /etc/nginx/nginx.conf

# The site itself — one file. .dockerignore keeps everything else (README,
# LICENSE, workflows, git metadata) out of the web root.
COPY index.html /usr/share/nginx/html/index.html

# The self-hosted typeface, so the page needs no request to fonts.googleapis.com
# (see fonts/README.md). Only the .woff2 goes in: the license text, the
# regeneration script and the coverage check stay in the repository.
COPY fonts/*.woff2 /usr/share/nginx/html/fonts/

# nginx runs unprivileged on 8080 and keeps its pid file and temp paths in /tmp,
# so the root filesystem can be mounted read-only. No chown is needed: the file
# above lands world-readable, and nothing writes below /var any more.
USER nginx

# Unprivileged port, because non-root may not bind below 1024.
# TLS and port 443 are handled by the reverse proxy in front.
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --spider http://127.0.0.1:8080/healthz || exit 1
