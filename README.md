# A Continuous Artifact

Book building script.

## Requirements

You'll need to get all these assets lined up before running initial setup.

### Software

- A modern Ruby with bundler
- SQLite (e.g. `brew install sqlite`)
- PDFJam (e.g. `brew install mactex-no-gui`)
- Weasyprint (e.g. `brew install weasyprint`)
- lipvips (e.g. `brew install vips`)

### Typefaces

- [Forevs](https://ohnotype.co/fonts/forevs)
- [Feature](https://commercialtype.com/catalog/feature)
- [Atlas Grotesk](https://commercialtype.com/catalog/atlas/atlas_grotesk)

### Book source code

- Clone this repo to your local machine

### Main set images

- Add the [CCGHQ MTG Pics](magnet:?xt=urn:btih:d35cbb070893e41df88c39db99f6cc869e7eb882&dn=CCGHQ%20MTG%20Pics&tr=udp%3A%2F%2Ftracker.opentrackr.org%3A1337&tr=udp%3A%2F%2Fopen.stealth.si%3A80%2Fannounce&tr=udp%3A%2F%2Ftracker.torrent.eu.org%3A451%2Fannounce&tr=udp%3A%2F%2Ftracker.bittor.pw%3A1337%2Fannounce&tr=udp%3A%2F%2Fpublic.popcorn-tracker.org%3A6969%2Fannounce&tr=udp%3A%2F%2Ftracker.dler.org%3A6969%2Fannounce&tr=udp%3A%2F%2Fexodus.desync.com%3A6969&tr=udp%3A%2F%2Fopen.demonii.com%3A1337%2Fannounce) torrent to your BitTorrent client of choice
- When your download config pops up, you can be selective about what to download—specifically, within the `XLHQs/Base and Expansion Sets` folder you'll want the OSM set zips:
  - 2ED
  - 3ED
  - ARN
  - ATQ
  - DRK
  - FEM
  - LEA
  - LEB
  - LEG
- Expand the zips and put the subfolders (`2ED`, `3ED`, etc.) in a `pics` folder at the root of this repo

### Promo card images

- Add the [CCGHQ XLHQ Promos Torrent](magnet:?xt=urn:btih:e9b27add0a5a0f53f3c46c39eb9c27f02899cb32&dn=XLHQ%20Promos&tr=udp%3A%2F%2Ftracker.openbittorrent.com%3A80&tr=udp%3A%2F%2Fopentor.org%3A2710&tr=udp%3A%2F%2Ftracker.ccc.de%3A80&tr=udp%3A%2F%2Ftracker.blackunicorn.xyz%3A6969&tr=udp%3A%2F%2Ftracker.coppersurfer.tk%3A6969&tr=udp%3A%2F%2Ftracker.leechers-paradise.org%3A6969) torrent to your client as well
  — Specifically, you'll want:
  - `XLHQ Promos/Convention Promos/DragonCon/Nalathni Dragon.xlhq.jpg`
  - `XLHQ Promos/Media Inserts/HarperPrism/Arena.xlhq.jpg`
  - `XLHQ Promos/Media Inserts/HarperPrism/Sewers of Estark.xlhq.jpg`
- Store these 3 files in `/pics/promos`

### Card data

- Create a `data` folder in the root of your repo
- Download [`AllPrintings.sqlite` and `AllPrices.json`](https://mtgjson.com/downloads/all-files/) and expand into `data`

## Initial setup

You should only need to do this once, or as often as you update your pricing and reprints files.

- `bundle install`
- `bundle exec rake setup` — this runs six setup tasks:
  1. `normalize` — adjusts some filenames from the image torrents to match card names
  1. `check` — checks to make sure you have all the files we need (see Requirements)
  1. `transform` SLOW — transforms all the card images to round their corners at the appropriate radius
  1. `pricing` SLOW — generate the pricing cache
  1. `sets` — generate the set metadata cache
  1. `reprints` SLOW — generate a reprints cache

## Building the book

- `bundle exec rake`, after which you can use `bundle exec rake open` to open the resulting imposed PDF file

This command produces 3 artifacts (!) which are useful for various purposes, all in the `build` directory:

- `book.html` — an HTML version of the book. Many print-specific features will be broken, but still useful for debugging.
- `book.pdf` — a PDF with one page per page. Most printers will want this file.
- `book-imposed.pdf` — a PDF with one _spread_ per page. This is best for viewing on screen.
