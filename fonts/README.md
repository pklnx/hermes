# Self-hosted webfonts

The page sets its type in **IBM Plex Mono** and **IBM Plex Sans**, the two faces
of the pklnx.space design system, and serves both from this origin. Loading them
from `fonts.googleapis.com` would send every visitor's IP address to a third
party and break the site's zero-external-requests rule — and with it the
consent-free operation the whole setup rests on (see `CLAUDE.md`).

## Credit & licence

> IBM Plex Mono and IBM Plex Sans — © 2017 IBM Corp., with Reserved Font Name "Plex"
> <https://github.com/IBM/plex>
> Licensed under the SIL Open Font License, Version 1.1.

Both families ship the same licence text, copied unchanged from the upstream
release as `OFL-IBMPlex.txt`. It goes into the container image next to the font
files: the OFL requires the licence to travel with the font, so it has to be part
of what the server hands out, not just of the repository. The attribution is
repeated in the `@font-face` comments in `index.html`.

IBM Plex reserves the name "Plex". A file we modified ourselves (and a subset is
a modification) could not be called IBM Plex. The page therefore ships IBM's own
pre-split Latin1 files **unmodified**.

## What is in here

| File                      | Face                    | Used for                         |
|---------------------------|-------------------------|----------------------------------|
| `ibm-plex-mono-400.woff2` | IBM Plex Mono Regular   | whois labels and values, footer  |
| `ibm-plex-mono-600.woff2` | IBM Plex Mono SemiBold  | the `$` prompts                  |
| `ibm-plex-sans-400.woff2` | IBM Plex Sans Regular   | eyebrow, intro line and motd     |
| `OFL-IBMPlex.txt`         | licence for both        |                                  |

The logo is not set in a webfont at all: the mark comes from the design system's
logo files, and the `hermes` wordmark is generated from IBM Plex Mono Bold on the
same grid. Both are inline SVG, so they look the same before the fonts arrive.

IBM Plex Mono is `IBMPlexMono-{Regular,SemiBold}-Latin1.woff2` from the
`@ibm/plex-mono` package, version **2.5.0** (`fonts/split/woff2/`), ~18 KB each:
the same release the design system builds its wordmark from. IBM Plex Sans is
`IBMPlexSans-Regular-Latin1.woff2` from the `@ibm/plex-sans` package, version
**1.1.0** (`fonts/split/woff2/`), ~21 KB. About 56 KB for the page in total.

## Reproducing the files

```sh
npm pack @ibm/plex-mono@2.5.0 @ibm/plex-sans@1.1.0
mkdir mono sans
tar xzf ibm-plex-mono-2.5.0.tgz -C mono
tar xzf ibm-plex-sans-1.1.0.tgz -C sans

# IBM's own Latin1 splits, copied as is. Do not subset them.
cp mono/package/fonts/split/woff2/IBMPlexMono-Regular-Latin1.woff2  fonts/ibm-plex-mono-400.woff2
cp mono/package/fonts/split/woff2/IBMPlexMono-SemiBold-Latin1.woff2 fonts/ibm-plex-mono-600.woff2
cp sans/package/fonts/split/woff2/IBMPlexSans-Regular-Latin1.woff2  fonts/ibm-plex-sans-400.woff2
cp sans/package/LICENSE.txt fonts/OFL-IBMPlex.txt   # identical to mono/package/LICENSE.txt
```

IBM's Latin1 files cover Basic Latin, Latin-1 Supplement, the common
punctuation (dashes, quotes, ellipsis) and the euro sign. If the page ever
needs a character outside that, use IBM's matching split file (`-Latin2`,
`-Latin3`, …) with a `unicode-range`, never a subset of our own.

Updating to a newer upstream release means re-running the block above and
checking the page at desktop and mobile width; nothing else references the
versions.
