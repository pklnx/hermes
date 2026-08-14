# Fonts

## JetBrains Mono

The page is set in **[JetBrains Mono](https://www.jetbrains.com/lp/mono/)**, designed by
**JetBrains**. Thank you — it is what makes the terminal look on this page work.

The typeface is licensed under the **SIL Open Font License 1.1** (see [`OFL.txt`](OFL.txt))
and is free for commercial and non-commercial use. JetBrains does not require attribution;
this credit is here because the work deserves it.

| | |
|---|---|
| Upstream | <https://github.com/JetBrains/JetBrainsMono> |
| Version | 2.304 |
| Source file | `fonts/variable/JetBrainsMono[wght].ttf` (variable, weight axis 100–800) |
| Archive sha256 | `6f6376c6ed2960ea8a963cd7387ec9d76e3f629125bc33d1fdcd7eb7012f7bbf` |
| Shipped as | `jetbrains-mono.<sha256[:8]>.woff2`, ~57 kB |

### Why it is vendored at all

The page must issue **zero external requests** — that is what lets it run without a consent
banner, and a `fonts.googleapis.com` request would hand every visitor's IP address to
Google. The original draft of this page did exactly that. Self-hosting is the only way to
keep the typeface and the rule at the same time; the CSP in `docker/nginx.conf` therefore
allows `font-src 'self'` and nothing else.

### Why it is subsetted

The full variable font is ~300 kB against an HTML file of ~5 kB. The subset carries Latin-1,
Latin Extended-A, monotonic Greek, General Punctuation, the euro sign, arrows and the
replacement character — ~57 kB, one file, every weight from 100 to 800.

**Two characters of `Ἑρμῆς` are not in the font at all.** JetBrains Mono covers monotonic
Greek but not the polytonic Extended Greek block, so `Ἑ` (U+1F19) and `ῆ` (U+1FC6) render in
the platform monospace face. That is not a consequence of the subset — the full font does
not have them either, and the Google Fonts version of this page rendered them no better.
`check-coverage.py` knows about both and passes them.

### Regenerating

```sh
pip install fonttools brotli
sh fonts/subset.sh          # downloads, verifies, subsets, prints the new src line
```

The filename carries a content hash, so a regenerated subset lands under a new URL and the
one-year cache in `docker/nginx.conf` can never serve a stale file. The script prints the
`src:` line for the `@font-face` block in `index.html`; paste it and then run:

```sh
python3 fonts/check-coverage.py
```

which asserts that the file `index.html` points at exists and covers every character on the
page. CI runs the same check, so a copy edit that introduces an uncovered glyph fails the
build instead of quietly rendering in the fallback face.

Subsetting happens **by hand and is committed** — the site keeps its "no build step"
property, and the image build stays a pure `COPY`.

### What ships in the image

Only `*.woff2`. `OFL.txt`, this file and the scripts stay in the repository (`.dockerignore`
is an allow-list). The OFL's redistribution requirement is met by the license text living
alongside the font here, in public, in the repository that contains it.
