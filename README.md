# Eric Kofman — personal site

A single-page portfolio built as a "darkened stage": each area of work is lit
by its own spotlight as you scroll into it.

## Structure
```
site/
├── index.html          all the page content
├── css/styles.css      the design system (colors, type, layout, animation)
├── scripts/main.js     scroll reveals, sticky nav + headings, mobile menu, role rotator
├── images/             headshot, banners, logo, photos — and your cartoon images
├── files/              downloadable files (e.g. a comic PDF)
└── fonts/              your licensed Latin CT webfont files (see fonts/README.txt)
```

## Run it
Open `index.html` in any browser — no build step, no server needed.
(To host it: upload the whole folder to Netlify, GitHub Pages, etc.)

## Editing notes
- **Your name / identity** appears in `index.html` (title, marquee, hero, footer).
  I inferred "Eric Kofman" from your materials — find & replace if that's off.
- **Add cartoons & paintings:** put images (any names) into `images/artwork/cartoons/` and `images/artwork/paintings/`, then run `bash build-artwork.sh` from the site folder. It makes fast-loading thumbnails (via macOS's `sips`) and lists them automatically under the Cartoons and Paintings subsections — no renaming, no editing `index.html`. Clicking an image opens it full-size in a lightbox. Re-run the script after adding/removing images. (To add another group like "sketches", see `images/artwork/README.txt`.)
- **Add a comic PDF:** a PDF can't render inside an image frame. Put it in `files/`
  and uncomment the `frame frame--pdf` download tile in the gallery grid, pointing
  `href` at your file.
- **Latin CT (playbill name):** paid font — add the licensed webfont files to `fonts/`
  to activate it (see `fonts/README.txt`). Falls back to Cinzel until then.
- **Add a section:** copy an existing `<section class="act …>` block, give it a new
  `id` and `data-accent`, and add a matching link in the top `<nav>`.
- **Colors / fonts** live at the top of `css/styles.css` under `:root`.
  Each act's spotlight color is the `--accent` on its section.
