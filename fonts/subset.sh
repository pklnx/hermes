#!/usr/bin/env sh
# Regenerate the self-hosted JetBrains Mono subset.
#
#   pip install fonttools brotli
#   sh fonts/subset.sh
#
# Downloads the upstream release, subsets the variable font to the ranges this
# page needs, and writes fonts/jetbrains-mono.<hash>.woff2. The hash is content
# derived: a regenerated subset lands under a new name, which is what lets
# docker/nginx.conf cache the file for a year without ever serving a stale one.
#
# The script does NOT edit index.html. It prints the @font-face src line to
# paste, and fonts/check-coverage.py (run in CI) fails the build if the file
# index.html points at is missing or does not cover the page.
#
# This runs by hand, not in CI or during the image build: the result is
# committed, so the site keeps its "no build step" property.
set -eu

VERSION="2.304"
URL="https://github.com/JetBrains/JetBrainsMono/releases/download/v${VERSION}/JetBrainsMono-${VERSION}.zip"
# sha256 of the upstream archive, recorded when the font was first vendored.
# A mismatch means upstream re-cut the release — check what changed before
# trusting it, don't just update the line.
SHA256="6f6376c6ed2960ea8a963cd7387ec9d76e3f629125bc33d1fdcd7eb7012f7bbf"

# What the subset carries. Latin-1 plus Latin Extended-A for European names,
# monotonic Greek for "Ἑρμῆς" (the polytonic accents are not in the font at all
# — see check-coverage.py), General Punctuation for the dashes and the German
# quotes, the arrow for the footer link, and the replacement character.
UNICODES="U+0020-007E,U+00A0-00FF,U+0100-017F,U+0370-03FF,U+2000-206F,U+20AC,U+2190-2193,U+2212,U+FEFF,U+FFFD"

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

echo "Downloading JetBrains Mono ${VERSION}…"
curl -fsSL "$URL" -o "$tmp/jbm.zip"

echo "$SHA256  $tmp/jbm.zip" | sha256sum -c - >/dev/null || {
  echo "checksum mismatch — refusing to vendor this archive" >&2
  exit 1
}

unzip -q "$tmp/jbm.zip" -d "$tmp/jbm"

# The variable font, so one file covers every weight the page uses (400 body,
# 500 prompt, 700 wordmark and header) instead of three static cuts.
pyftsubset "$tmp/jbm/fonts/variable/JetBrainsMono[wght].ttf" \
  --output-file="$tmp/subset.woff2" \
  --flavor=woff2 \
  --unicodes="$UNICODES" \
  --layout-features='*' \
  --name-IDs='*' \
  --notdef-outline

hash=$(sha256sum "$tmp/subset.woff2" | cut -c1-8)
out="$here/jetbrains-mono.$hash.woff2"

rm -f "$here"/jetbrains-mono.*.woff2
cp "$tmp/subset.woff2" "$out"
cp "$tmp/jbm/OFL.txt" "$here/OFL.txt"

echo
echo "Wrote $(basename "$out") ($(wc -c < "$out") bytes)"
echo
echo "Now put this into the @font-face block in index.html:"
echo
echo "    src: url('/fonts/jetbrains-mono.$hash.woff2') format('woff2');"
echo
echo "then verify with: python3 fonts/check-coverage.py"
