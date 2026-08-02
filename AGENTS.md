# AGENTS.md

Working notes for agents on _Continuous Artifact_ — a print book cataloging all 988 cards
of the 1993–94 "Old School" (OS) _Magic: The Gathering_ card pool at actual size.

This is a **book**, not an app. The deliverable is a PDF that goes to a printer. There are no
tests; correctness means "the pages look right." Read [README.md](README.md) first for the
one-time asset setup (torrents, MTGJSON, typefaces) — that's not repeated here.

## Toolchain

Ruby **3.3.4** via chruby. A non-interactive shell lands on system Ruby 2.6 and `bundle` will
crash, so prefix Ruby work with:

```
source /opt/homebrew/opt/chruby/share/chruby/chruby.sh && chruby ruby-3.3.4
```

External binaries the Rakefile shells out to: `weasyprint`, `pdfjam` (mactex), `gs`, `jq`, `cpdf`.

## Pipeline

`rake` (default → `open`) chains: **build → render → impose → bookmarks → open**.

| Task | Does | Cost |
|---|---|---|
| `rake build` | `src/build.rb` renders `templates/book.html.erb` → `build/book.html` | ~4s |
| `rake render` | weasyprint `book.html` → `build/book.pdf` (one page per page) | ~40s |
| `rake impose` | pdfjam 2-up → `build/book-imposed.pdf` (one spread per page, 13×19in). The `'{},1-'` page spec injects a blank first so spreads pair correctly | ~15s |
| `rake bookmarks` | `src/bookmarks.rb` copies book.pdf's outline onto the imposed PDF via cpdf | ~3s |
| `rake open` | opens the imposed PDF | — |
| `rake compress` | ghostscript → dated low-res `build/continuous_artifact-preview-MM-DD-YY.pdf`, with `build/warning.pdf` prepended | slow |

A full run is ~70s end to end; the book is 153 pages (77 imposed sheets) and `book.pdf` lands
around 640 MB. Timings vary a fair bit with disk contention — 640 MB gets written twice.

### PDF bookmarks

`build/style/matter.css` sets `bookmark-level`/`bookmark-label`, which weasyprint turns into
book.pdf's outline. Two gotchas: weasyprint bookmarks **every heading by default**, so the CSS
resets `h1…h6 { bookmark-level: none }` first and opts specific headings back in; and a
`display: none` element generates no box and therefore no bookmark, which is why the per-color
entries hang off the intro headings rather than the hidden `section#cards > h2`.

pdfjam discards the outline entirely when imposing, so `src/bookmarks.rb` reads it back out of
book.pdf and re-applies it to the imposed file, mapping book page *n* to sheet `n / 2 + 1`. If you
change the pdfjam page spec, that formula has to change with it. `rake compress` prepends a warning
page and so does *not* get bookmarks.

**Iterate on `rake build` and inspect `build/book.html` in a browser.** Layout, pagination,
running heads, and page-number cross-references are all print-only and will look wrong there,
but it catches content and structural errors in seconds.

`rake setup` (normalize, check, pricing, sets, reprints, popularity) is a one-time thing and is
already done on this machine. Only re-run individual tasks when the upstream data files change.
`pricing` and `reprints` are slow; the network tasks (`sets`, `reprints` — Scryfall API, paged
with `sleep 1`) are idempotent.

## Layout of the repo

- `src/build.rb` — the whole build. Queries SQLite, groups cards, renders the ERB, writes
  `cache/reprint_sets.json` as a side effect.
- `src/card.rb` — `Card < Sequel::Model` over MTGJSON's `AllPrintings.sqlite`. Owns set codes,
  shorthand letters, price ranges, rarity, reprints, popularity stars, image path resolution.
- `src/deck.rb` — `Deck`/`DeckCard`, builds the 5 classic decks from `config/decks.csv` and packs
  them into 5 columns. `DEBUG=1` env var turns on its column-packing trace.
- `src/{sets,reprints,popularity}.rb` — cache generators, each run once by `rake setup`.
- `src/bookmarks.rb` — post-imposition step that restores the PDF outline.
- `templates/*.html.erb` — `book` (the spine of the whole document), `card`, `deck`, `stack`.
- `build/style/{main,cards,matter}.css` — hand-written print CSS. `main` = page geometry + vars,
  `cards` = the card grid and card pages, `matter` = front/back matter and named `@page` rules.
- `copy/**.md` — all prose, rendered through Tilt/rdiscount with smartypants.
- `config/` — `decks.csv`, `staples.csv`, `card_images.json` (the 2002-entry manifest `check`
  works from).
- `cache/`, `data/`, `pics/` — gitignored, large, machine-local.
- `build/` — CSS and images are tracked; the HTML and PDFs are gitignored.

## The asset folder outside the repo

`~/Documents/projects/aca` is where the author keeps everything that intentionally doesn't get
checked in. It predates this repo (the first commit is literally "import from aca repo"). Relevant
contents:

- **Design sources** for the images baked into `build/images/` — `cover*.ai`, `dj.*` (dust jacket),
  `parchment.ai`, `steady_hand_press.ai`, `printer.ai`, `locket.*` / `chain.*` (Dan Frazier art),
  plus `Andy R. Art Scans/` (multi-hundred-MB TIFF scans).
- **`oldschool_aggregates.csv.csv`** — byte-identical to `data/mtg-os_card_popularity.csv`. This is
  where the popularity data comes from; re-drop it here and copy it over to refresh the star ratings.
- **`pics-original/`** — the raw CCGHQ torrent downloads. The repo's `pics/` is a separate working
  copy, not a symlink.
- **`timmy.docx`** — the source document behind `copy/essay.md`.

Two caveats: much of the folder is abandoned experiments, so don't assume a file is in use just
because it's there; and some files are unresolved **git-lfs pointers** (`gamma.psd` is 133 bytes of
LFS metadata, not a PSD). Run `file` before treating a large-looking asset as real.

## Things that will bite you

**The build is non-deterministic.** `Card#picture_set_and_path` calls `.sample` over every OS-set
printing that has an image, so each build picks a different printing's art for multi-set cards.
Two consecutive builds are not diffable. Don't chase "changes" that are just re-sampling.

**Notes are placed by grid position.** A card with `copy/notes/<id>.md` renders an adjacent note
panel only when its grid position `p % 3` is 0 or 1 (i.e. not in the third column). `build.rb` has
a block of hand-written `delete_at`/`insert` swaps (Dark Ritual, Birds of Paradise, Marsh Viper,
Millstone, Tabernacle) purely to nudge noted cards into a workable column. Adding or removing any
note shifts every later position, so it can knock a *different* note out of the layout — that
cascade is real, not hypothetical.

`build.rb` now fails the build when that happens, naming the dropped cards, so you don't need to
check by hand. It also catches note files whose name matches no card. The fix for a dropped note
is to reorder the offending card in the swap block. If you touch that check, note it relies on the
`data-card` attribute emitted by `templates/card.html.erb`.

**Cross-references are CSS, not text.** In copy, a page reference is written
`p. [X](#card-id)` — the anchor text is hidden in print (`font-size: 0`) and the page number is
generated by `content: target-counter(attr(href), page)`. Never hand-write page numbers, and keep
the `X` placeholder. Anchor ids come from `Card#id`: lowercased name, spaces → hyphens,
non-word characters dropped.

**Placeholder tokens in copy** are substituted in `book.html.erb`, not by a general mechanism:
`$card_count` works only in `copy/preface.md` and `copy/introduction.md`; `$stamp` only in the CIP
page. Adding a token to a different file does nothing.

**`copy/cip-official.md`** is gitignored and, if present, overrides `copy/cip.md` — that's the real
Library of Congress data, intentionally kept out of the repo.

**Reprints need two builds when cold.** `build.rb` collects `$REPRINT_SETS` while rendering and
writes the cache afterward, so the reprint appendix reflects the *previous* build. It's warm here;
just be aware if the cache is ever deleted.

**Card ordering** is alphabetical within color, from a `select_group(:name)` query — one entry per
card name, aggregating printings/rarities/uuids/artists across sets. Colors are `W U B R G Z A L`
(`Z` = multicolor, `A` = artifact, `L` = land); `W U B R G` get a classic-deck spread first
(`Card::DECKED`), `Z A L` get a prose intro block instead (`Card::INTROD`).

**Everything renders from a single HTML file** — there is no per-chapter build. A CSS mistake in
one `@page` rule can silently repaginate the entire book.

## Print conventions in use

- Trim 9.5×13in; imposed spreads 13×19in landscape. Cards are real size: 63×88mm.
- Card corner radius 3mm, except Alpha (`LEA`) at 5mm — done purely in CSS via `border-radius` +
  `overflow: hidden` on `.pic`.

**Never feed weasyprint images with an alpha channel.** A JPEG with no alpha is copied into the
PDF verbatim as a DCTDecode stream, essentially for free. Add an alpha channel and weasyprint must
decode, build a soft mask, and re-deflate every image: benchmarked at **40x** the render time
(150 cards: 0.69s → 27.6s) and 3x the file size. The book used to pre-round corners into RGBA PNGs
via a `transform` step; that was removed once it turned out the CSS was already doing the clipping,
which took a full build from 3m57s to 56s and `book.pdf` from 1.87 GB to 640 MB. Card images are
now served straight from `pics/`. If corners ever need changing, change the CSS — don't reintroduce
baked masks.
- Typefaces are licensed and installed locally: Forevs Variable (display), Feature Text (body
  prose), Atlas Grotesk (UI/marginalia). Don't swap in substitutes.
- Named `@page` contexts: `Cards`, `Case`, `Cover`, `Matter`, `Blank`, `Endpapers`, `Pretitle`,
  `First`. Left/right variants carry the asymmetric margins and running heads.
- The book is **half-bound**: `@page Case` shows a preview of the marbled boards with leather spine
  and corners (`build/images/bg/cover.jpg`). There is no dust jacket — that direction was abandoned,
  so ignore the `dj.*` files in the asset folder. All the cover type lives in the artwork itself;
  the `#cover` section is deliberately empty.
- Endpapers are the same rust marbled paper as the boards, cropped from the raw scan at **1:1
  physical scale**: 19×13in of real paper at 288 ppi → 5472×3744, split across the spread by
  `background-position: left/right`. Print assets are CMYK with an embedded
  **U.S. Web Coated (SWOP) v2** profile — match that when regenerating any background.

**Page parity is load-bearing, front and back.** `:left`/`:right` rules set asymmetric margins and
the endpaper background split by page number, so adding or removing an *odd* number of pages flips
every left/right after that point. Two consequences:

- Changing front matter shifts the whole book. Change it in pairs, or check that each later section
  keeps its odd/even position.
- The back endpapers must land on a verso/recto pair or they stop forming a spread. `#postmatter`
  (an otherwise pointless blank right before them) exists purely to absorb the odd page the staples
  spread added. If you change the page count anywhere, re-check it — the total should stay odd so
  the endpapers sit on the last two pages as (even, odd).

Verify with: book page *n* is a recto when *n* is odd, and shares imposed sheet `n / 2 + 1` with its
partner. The staples spread depends on the same thing — it must start on a verso.

## Conventions

- Commit messages are short and imperative ("Edits", "Use 'OS' instead of 'OSM'"). Don't commit
  unless asked.
- Prose is the author's voice — don't rewrite copy uninvited.
- `README.md` and much of `copy/` use **em dash followed by a non-breaking space** (`e2 80 94 c2 a0`).
  String-matching edits fail confusingly if you type a normal space; check the bytes first.
- The code is deliberately plain, procedural, top-level-constant Ruby. Match it; this is not a
  codebase that wants refactoring into services and modules.
- Licensing is unusual and deliberate: the book is all-rights-reserved (Wizards' Fan Content
  Policy), the code is PolyForm Strict. Don't add card images or PDFs to git, and don't propose
  distributing build output.
