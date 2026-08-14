#!/usr/bin/env python3
"""Assert that the self-hosted subset covers every character on the page.

The font shipped in this repository is a *subset* — see fonts/README.md. That
keeps it at ~57 kB instead of ~300 kB, at the price of a quiet failure mode:
a character the subset does not carry renders in the fallback monospace face
instead, which on a page of this size is one visibly wrong glyph in an
otherwise uniform block of text. Nothing warns about it in a browser.

So CI runs this. It reads index.html, collects every character the page can
display, and checks it against the font's cmap.

    pip install fonttools brotli
    python3 fonts/check-coverage.py

Exits non-zero and names the offending characters if something is missing.
Requires fonttools only here and in CI — the site itself keeps its zero
dependencies.
"""

import re
import sys
import unicodedata
from pathlib import Path

from fontTools.ttLib import TTFont

REPO = Path(__file__).resolve().parent.parent
INDEX = REPO / "index.html"

# Characters that are knowingly NOT in the font and fall back on purpose.
# JetBrains Mono carries monotonic Greek (U+0370–U+03FF) but no polytonic
# Extended Greek, so the two accented letters of "Ἑρμῆς" render in the
# platform monospace face. Google Fonts served the same page no better: its
# latin subset had no Greek at all. Documented in README.md; remove an entry
# here only together with the character on the page.
ALLOWED_FALLBACK = {
    "Ἑ",  # Ἑ  GREEK CAPITAL LETTER EPSILON WITH DASIA
    "ῆ",  # ῆ  GREEK SMALL LETTER ETA WITH PERISPOMENI
}


def page_text(html: str) -> str:
    """Everything a visitor can see: markup, comments and <style> removed.

    Attribute values go too — they are colours and lengths, not text — except
    that dropping tags wholesale would also drop the ASCII wordmark, which
    lives in element content and is exactly what needs checking.
    """
    html = re.sub(r"<!--.*?-->", "", html, flags=re.S)
    html = re.sub(r"<style\b.*?</style>", "", html, flags=re.S | re.I)
    html = re.sub(r"<head\b.*?</head>", "", html, flags=re.S | re.I)
    html = re.sub(r"<[^>]+>", "", html)
    # Named and numeric entities resolve to characters the font has to carry.
    html = html.replace("&nbsp;", " ").replace("&amp;", "&")
    html = html.replace("&lt;", "<").replace("&gt;", ">").replace("&quot;", '"')
    html = re.sub(r"&#(\d+);", lambda m: chr(int(m.group(1))), html)
    html = re.sub(r"&#x([0-9a-fA-F]+);", lambda m: chr(int(m.group(1), 16)), html)
    return html


def main() -> int:
    html = INDEX.read_text(encoding="utf-8")

    match = re.search(r"url\('(/fonts/[^']+\.woff2)'\)", html)
    if not match:
        print("no @font-face url found in index.html", file=sys.stderr)
        return 1
    font_path = REPO / match.group(1).lstrip("/")
    if not font_path.is_file():
        print(f"index.html references {match.group(1)}, which does not exist",
              file=sys.stderr)
        return 1

    cmap = TTFont(font_path).getBestCmap()

    missing = {}
    for ch in page_text(html):
        if ch in "\r\n\t" or ch in ALLOWED_FALLBACK or ord(ch) in cmap:
            continue
        missing[ch] = missing.get(ch, 0) + 1

    if missing:
        print(f"{font_path.name} does not cover every character on the page:",
              file=sys.stderr)
        for ch, count in sorted(missing.items()):
            name = unicodedata.name(ch, "unnamed")
            print(f"  U+{ord(ch):04X}  {ch!r}  {name}  ({count}x)",
                  file=sys.stderr)
        print("\nWiden the --unicodes ranges in fonts/subset.sh and regenerate,"
              "\nor add the character to ALLOWED_FALLBACK if the fallback face"
              "\nis genuinely acceptable for it.", file=sys.stderr)
        return 1

    print(f"{font_path.name} covers every character on the page "
          f"({len(ALLOWED_FALLBACK)} documented fallbacks)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
