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
