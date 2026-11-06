# Notes for Claude

Static single-page site. No build step, no framework, no dependencies — just
`index.html`, `css/styles.css`, `scripts/main.js`. Open `index.html` directly to
preview, or `python3 -m http.server` if you need real URLs (the gallery fetches
`images/artwork/manifest.js`, which works from `file://` but URL-encoded paths are
easier to sanity-check over HTTP).

## Publishing changes

The repo **is** the deploy target. GitHub Pages serves the working tree of `main`.

```
git add -A && git commit -m "..." && git push origin main
```

That's the whole deploy. Pages rebuilds in well under a minute, then
https://erickofman.com serves it. Verify rather than assume — the push succeeding
only means GitHub got the commit, not that it rebuilt:

```
until ! curl -s https://erickofman.com/ | grep -q "<old text>"; do sleep 5; done
```

Run that with `run_in_background: true` and keep working; you'll be notified.

Local CSS/JS links carry a content-hash `?v=` stamp so phones refetch changed
files instead of serving a cached copy for the rest of Pages' 10-minute max-age.
`stamp-assets.sh` rewrites them; a local pre-commit hook (`.git/hooks/pre-commit`,
not in the repo) runs it and re-adds the HTML. If the hook is gone, run
`bash stamp-assets.sh` before committing. The hook must be reinstalled on a fresh
clone:

```
printf '#!/usr/bin/env bash\nbash stamp-assets.sh && git add -- *.html\n' > .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
```

Ask before pushing unless the user has said to. Edits here are outward-facing —
this is a live personal site under the user's own name.

### Deployment facts worth not rediscovering

- Repo `ekofman/ekofman.github.io`, branch `main`, path `/`.
- Custom domain `erickofman.com`, HTTPS enforced. **Do not delete the `CNAME`
  file** — Pages reads it, and losing it drops the domain back to `ekofman.github.io`.
- `.nojekyll` disables Jekyll processing. Leave it.
- Branch `master` holds the user's 2015 site, kept deliberately as an archive.
  Never force-push over it or delete it.
- DNS lives at GoDaddy: apex `A` → GitHub's four IPs, `www` CNAME → `ekofman.github.io`.
  The `MX` records point at `secureserver.net` and carry the user's real email —
  never touch them.
- If the site looks stale or 404s from the user's machine but `dig @1.1.1.1` shows
  the right records, it's their router's DNS cache (`192.168.1.254`), not the site.

## Images — the part that's easy to get wrong

**Never point HTML or JS at an original image file.** Originals are masters kept in
the repo; the site only ever serves WebP derivatives. This exists because the
gallery was 11.5 MB of thumbnails and slow on phones — it's now ~2.7 MB.

Artwork (`images/artwork/<group>/`) is fully automated. After the user adds or
removes files there:

```
bash build-artwork.sh
```

It rewrites `manifest.js`, generates both derivatives per image, and deletes
orphans. It only rebuilds files whose original is newer, so re-running is cheap.

```
images/artwork/cartoons/Foo.png          <- master, never served
images/artwork/cartoons/thumbs/Foo.webp  <- 600px  q76, the grid
images/artwork/cartoons/web/Foo.webp     <- 1600px q82, the lightbox
```

`main.js` derives those paths by swapping the extension for `.webp`, and falls
back to the original if a derivative 404s — so a missing derivative degrades
quietly instead of showing a broken image. Don't "fix" a slow-loading image by
repointing it at the original; regenerate the derivative.

### Snow White show page (`snow-white.html`)

Cast and creative-team cards come from a bios document that lives **outside the
repo**, with the show's other assets:

```
/Users/erickofman/Documents/SnowWhiteMusical/Assets/Headshots/descriptions.txt
```

Its format (one `== Name | Role | photo | focal-point` line per person, then bio
paragraphs; `[Cast]` / `[Creative team]` group headers) is documented at the top
of the file. After the user edits it or drops in new headshots:

```
bash build-snowwhite.sh
```

That parses the doc into `images/snowwhite/people.js`, converts each headshot to
`images/snowwhite/people/<slug>.webp`, converts the six RealiTea logo variants to
`images/snowwhite/logo/<n>.webp` (the scroll-linked logo), builds the production
photos (below), and deletes photos for people removed from the doc. `scripts/snowwhite.js` renders
the cards. Don't hand-edit `people.js` or add people in the HTML — edit the doc
and rerun. The ticket link is the Ludus public events page
(`miragefactory.ludus.com/index.php?sections=events`); `/admin/…` Ludus URLs are
the logged-in dashboard and won't work for visitors.

The same script builds the **production-photo filmstrip** at the top of the show
page from another folder outside the repo:

```
/Users/erickofman/Documents/SnowWhiteMusical/Assets/PhotosAndVideos/Show/SevenMillionShowPhotos_October 18_ 2026
```

Each master becomes `images/snowwhite/show/thumbs/<id>.webp` (600px, the strip)
and `images/snowwhite/show/web/<id>.webp` (1600px, the lightbox), where `<id>` is
the photographer's frame number from the filename (`…_0129.jpg` -> `0129`), plus a
line in `images/snowwhite/show.js` carrying the master's pixel size. The strip
reserves each tile's width from that size, so 229 lazy-loading thumbnails don't
shift the page as they arrive. 229 photos is about 70 seconds of `cwebp` on a
cold run; after that it only rebuilds what changed. To drop or add photos, change
the folder and rerun — stale derivatives are deleted for you. The photographer's
credit and her link are hand-written in `snow-white.html` (`.filmstrip__note`),
not derived from the filenames.

The **Videos** section is not generated — the five YouTube clips are hand-picked
and written into `snow-white.html` the way the home page's `.showreel` photos are.
Each `.video` carries `data-yt` (the id) and `data-title`; `scripts/snowwhite.js`
leaves it as a poster image until it is clicked, then replaces the tile with a
`youtube-nocookie` iframe. Five live embeds would be megabytes of player JS on a
page that already lazy-loads 229 thumbnails, so don't "simplify" the facade into
plain iframes. Posters come from `i.ytimg.com/vi/<id>/maxresdefault.jpg`, with a
JS fallback to `sddefault` then `hqdefault` — YouTube 404s maxres for sources
under 1280px wide rather than substituting a smaller one.

The same derivatives feed the cycling frame beside the banner on `index.html`
(`.showreel`). Those six photos are picked by hand and listed in the HTML; the
crossfade is pure CSS, one shared loop with a per-image `--i` delay. The Haber card
uses the same marquee (logo as the banner, reading photos as the reel), but only
two photographs survive from the 2019 Armory reading, so it carries
`.showreel--pair`: same 3.2s slot and crossfade, a two-slot keyframe set instead
of six. If more Haber photos ever turn up, drop `--pair` and give them `--i:2`
upward on the default loop.

Non-artwork images (banners, headshot, logo) are **not** covered by the script.
Convert by hand and update the `src` in `index.html`:

```
cwebp -quiet -q 82 -resize 1600 0 images/foo.png -o images/foo.webp
```

Requires `cwebp` (`brew install webp`). Use `-resize 0 <n>` for portrait images —
the zero goes on the axis you want computed from the aspect ratio.

### zsh gotcha

The user's shell is zsh, which does **not** word-split unquoted variables the way
bash does. `rz="-resize 600 0"; cwebp $rz ...` passes the whole string as one
argument and fails with "Unknown option". `build-artwork.sh` passes resize
arguments as separate literal words for this reason — don't refactor them back
into a variable. Run it as `bash build-artwork.sh`.

## Content conventions

- Buttons in `.show__actions` use sentence case ("Read the synopsis"). One
  `btn--solid` per group is the prominent slot; the rest are `btn--ghost`.
- Each `<section class="act">` carries a `data-accent` that drives its spotlight
  color; per-act colors live in `:root` in `styles.css`.
- Adding a section means copying an `act` block, giving it a new `id` and
  `data-accent`, and adding a matching link in the top `<nav>`.

See `README.md` for the user-facing version of the editing notes.
