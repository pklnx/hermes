# Self-hosted webfonts

The page sets its type in **Space Mono** and **IBM Plex Sans** and serves both
from this origin. Loading them from `fonts.googleapis.com` would send every
visitor's IP address to a third party and break the site's zero-external-requests
rule — and with it the consent-free operation the whole setup rests on (see
`CLAUDE.md`).

## Credit & licence

> Space Mono — © 2016 The Space Mono Project Authors
> <https://github.com/googlefonts/spacemono>
> Licensed under the SIL Open Font License, Version 1.1.

> IBM Plex Sans — © 2017 IBM Corp., with Reserved Font Name "Plex"
> <https://github.com/IBM/plex>
> Licensed under the SIL Open Font License, Version 1.1.

Each family's licence text is copied unchanged from its upstream release and
ships into the container image next to the font files: the OFL requires the
licence to travel with the font, so it has to be part of what the server hands
out, not just of the repository. The attribution is repeated in the
`@font-face` comments in `index.html`.

The two licences differ in one point that decides how each file is produced:

- **Space Mono** carries no Reserved Font Name, so subsetting it while keeping
  the family name is permitted.
- **IBM Plex** reserves the name "Plex". A file we modified ourselves (and a
  subset is a modification) could not be called IBM Plex Sans. The page
  therefore ships IBM's own pre-split Latin1 file **unmodified**.

## What is in here

| File                      | Face                    | Used for                         |
|---------------------------|-------------------------|----------------------------------|
| `space-mono-400.woff2`    | Space Mono Regular      | eyebrow, whois labels and values, footer |
| `space-mono-700.woff2`    | Space Mono Bold         | the `$` prompts                  |
| `ibm-plex-sans-400.woff2` | IBM Plex Sans Regular   | intro line and motd              |
| `OFL-SpaceMono.txt`       | licence for Space Mono  |                                  |
| `OFL-IBMPlex.txt`         | licence for IBM Plex    |                                  |

The logo is not set in a webfont at all: the mark and the `hermes` wordmark are
inline SVG, converted from Space Mono Bold once, so they look the same before the
fonts arrive.

Space Mono comes from the upstream repository at commit
`329858c2c4dbd3476f972a4ae00624b018cf4b81` (`fonts/ttf/`), subset to Latin:
~15 KB per weight. IBM Plex Sans is `IBMPlexSans-Regular-Latin1.woff2` from the
`@ibm/plex-sans` package, version **1.1.0** (`fonts/split/woff2/`), ~21 KB.
About 50 KB for the page in total.

## Reproducing the files

```sh
pip install fonttools brotli

# Space Mono: subset the upstream TTFs to Latin.
git clone https://github.com/googlefonts/spacemono
git -C spacemono checkout 329858c2c4dbd3476f972a4ae00624b018cf4b81

RANGES="U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,U+0304,\
U+0308,U+0329,U+2000-206F,U+2074,U+20AC,U+2122,U+2190-2193,U+2212,U+2215,U+FEFF,U+FFFD"

for pair in Regular:400 Bold:700; do
  pyftsubset "spacemono/fonts/ttf/SpaceMono-${pair%%:*}.ttf" \
    --unicodes="$RANGES" \
    --layout-features='kern,mark,mkmk,ccmp,locl' \
    --flavor=woff2 \
    --output-file="fonts/space-mono-${pair##*:}.woff2"
done
cp spacemono/OFL.txt fonts/OFL-SpaceMono.txt

# IBM Plex Sans: IBM's own Latin1 split, copied as is. Do not subset it.
npm pack @ibm/plex-sans@1.1.0
mkdir plex && tar xzf ibm-plex-sans-1.1.0.tgz -C plex
cp plex/package/fonts/split/woff2/IBMPlexSans-Regular-Latin1.woff2 fonts/ibm-plex-sans-400.woff2
cp plex/package/LICENSE.txt fonts/OFL-IBMPlex.txt
```

IBM's Latin1 file covers Basic Latin, Latin-1 Supplement, the common
punctuation (dashes, quotes, ellipsis) and the euro sign. If the prose lines ever
need a character outside that, use IBM's matching split file (`-Latin2`,
`-Latin3`, …) with a `unicode-range`, never a subset of our own.

Updating to a newer upstream release means re-running the block above and
checking the page at desktop and mobile width; nothing else references the
versions.
