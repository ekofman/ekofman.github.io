#!/bin/bash
# Builds the cast & creative-team data for snow-white.html from the bios
# document kept with the show's assets (outside this repo), and copies the
# headshots in as small WebP files.
#
#   source of truth:  $ASSETS/Headshots/descriptions.txt   (names, roles, photos, bios)
#   writes:           images/snowwhite/people.js           (read by scripts/snowwhite.js)
#                     images/snowwhite/people/<slug>.webp  (one per person with a photo)
#                     images/snowwhite/logo/<n>.webp               (RealiTea logo variants)
#
# It also builds the production-photo filmstrip at the top of the page from the
# photographer's folder (also outside the repo):
#
#   source of truth:  $SHOWPHOTOS/*.jpg                     (the masters)
#   writes:           images/snowwhite/show.js              (the manifest)
#                     images/snowwhite/show/thumbs/<id>.webp   600px - the strip
#                     images/snowwhite/show/web/<id>.webp     1600px - the lightbox
#
# The format of descriptions.txt is explained at the top of that file.
# Originals are never modified and never served — only the WebP copies are.
#
# Usage:  bash build-snowwhite.sh      (run from the site folder)
cd "$(dirname "$0")" || exit 1

ASSETS="/Users/erickofman/Documents/SnowWhiteMusical/Assets"
BIOS="$ASSETS/Headshots/descriptions.txt"
OUTDIR="images/snowwhite"
PEOPLE="$OUTDIR/people"
PHOTO_MAX=900     # cards render ~300px wide, so 900 covers 3x screens
PHOTO_QUALITY=80

# production photos (the filmstrip under the banner). Same two-derivative scheme
# as build-artwork.sh: a small tile for the strip, a bigger one for the lightbox.
SHOWPHOTOS="$ASSETS/PhotosAndVideos/Show/SevenMillionShowPhotos_October 18_ 2026"
GALLERY="$OUTDIR/show"
STRIP_MAX=600     # tiles render ~150-260px tall
STRIP_QUALITY=76
FULL_MAX=1600     # the lightbox is viewed close-up
FULL_QUALITY=82

[ -f "$BIOS" ] || { echo "error: bios file not found: $BIOS"; exit 1; }
mkdir -p "$PEOPLE"

have_cwebp=0
command -v cwebp >/dev/null 2>&1 && have_cwebp=1
[ "$have_cwebp" -eq 1 ] || echo "note: 'cwebp' not found - skipping image conversion (brew install webp)."

# Same helper as build-artwork.sh: shrink to at most $3 px on the long edge,
# passing -resize args as separate words (zsh doesn't word-split variables).
make_webp() {
  src="$1"; dest="$2"; max="$3"; q="$4"
  # cwebp only reads PNG/JPEG/TIFF/WebP; hand AVIF/HEIC through sips as a PNG first.
  case "$src" in
    *.avif|*.AVIF|*.heic|*.HEIC)
      tmp=$(mktemp -t snowwhite).png
      sips -s format png "$src" --out "$tmp" >/dev/null 2>&1 || { echo "  warning: could not decode $src"; return; }
      make_webp "$tmp" "$dest" "$max" "$q"; rm -f "$tmp"; return;;
  esac
  w=$(sips -g pixelWidth "$src" 2>/dev/null | awk '/pixelWidth/{print $2}')
  h=$(sips -g pixelHeight "$src" 2>/dev/null | awk '/pixelHeight/{print $2}')
  [ -n "$w" ] && [ -n "$h" ] || { cwebp -quiet -q "$q" "$src" -o "$dest" >/dev/null 2>&1; return; }
  if [ "$w" -ge "$h" ]; then
    if [ "$w" -gt "$max" ]; then
      cwebp -quiet -q "$q" -resize "$max" 0 "$src" -o "$dest" >/dev/null 2>&1; return
    fi
  elif [ "$h" -gt "$max" ]; then
    cwebp -quiet -q "$q" -resize 0 "$max" "$src" -o "$dest" >/dev/null 2>&1; return
  fi
  cwebp -quiet -q "$q" "$src" -o "$dest" >/dev/null 2>&1
}

# ---- 1. Parse the bios file into people.js and a list of photos to convert ----
# python3 (stdlib only) does the text parsing; it prints "slug<TAB>photo path"
# lines for the shell loop below.
photos=$(python3 - "$BIOS" "$OUTDIR/people.js" <<'PY'
import json, re, sys
src, out = sys.argv[1], sys.argv[2]

def slug(s):
    s = re.sub(r"[^a-z0-9]+", "-", s.lower()).strip("-")
    return s or "person"

groups, person, para = [], None, []

def flush_para():
    global para
    if person is not None and para:
        person["bio"].append(" ".join(para).strip())
    para = []

for raw in open(src, encoding="utf-8"):
    line = raw.rstrip("\n")
    s = line.strip()
    if s.startswith("#"):
        continue
    if s.startswith("[") and s.endswith("]"):
        flush_para(); person = None
        groups.append({"name": s[1:-1].strip(), "people": []})
        continue
    if s.startswith("=="):
        flush_para()
        parts = [p.strip() for p in s[2:].split("|")]
        while len(parts) < 4: parts.append("")
        name, role, photo, focus = parts[0], parts[1], parts[2], parts[3]
        if not groups:
            groups.append({"name": "Cast", "people": []})
        person = {"name": name, "role": role, "slug": slug(name),
                  "photo": photo, "focus": focus, "bio": []}
        groups[-1]["people"].append(person)
        continue
    if not s:
        flush_para(); continue
    if person is not None:
        para.append(s)
flush_para()

# make slugs unique, then emit the JS the page reads
seen = {}
for g in groups:
    for p in g["people"]:
        n = seen.get(p["slug"], 0) + 1; seen[p["slug"]] = n
        if n > 1: p["slug"] += "-%d" % n
        p["image"] = "images/snowwhite/people/%s.webp" % p["slug"] if p["photo"] else ""

with open(out, "w", encoding="utf-8") as f:
    f.write("/* Auto-generated by build-snowwhite.sh from the show's descriptions.txt - do not edit by hand. */\n")
    f.write("window.SNOWWHITE_PEOPLE = ")
    json.dump([{"name": g["name"],
                "people": [{k: p[k] for k in ("name", "role", "image", "focus", "bio")} for p in g["people"]]}
               for g in groups], f, ensure_ascii=False, indent=2)
    f.write(";\n")

for g in groups:
    sys.stderr.write("  %s: %d\n" % (g["name"], len(g["people"])))
    for p in g["people"]:
        if p["photo"]:
            print(p["slug"] + "\t" + p["photo"])
PY
) || exit 1

# ---- 2. Convert each headshot (only when the original is newer) ----
wanted=""
while IFS=$'\t' read -r slug photo; do
  [ -n "$slug" ] || continue
  case "$photo" in /*) src="$photo";; *) src="$ASSETS/Headshots/$photo";; esac
  dest="$PEOPLE/$slug.webp"
  wanted="$wanted $slug.webp"
  if [ ! -f "$src" ]; then
    echo "  warning: photo not found for $slug: $src"; continue
  fi
  if [ "$have_cwebp" -eq 1 ]; then
    [ -f "$dest" ] && [ ! "$src" -nt "$dest" ] || { make_webp "$src" "$dest" "$PHOTO_MAX" "$PHOTO_QUALITY"; echo "  converted $dest"; }
  fi
done <<< "$photos"

# clear out photos for people no longer in the file
for g in "$PEOPLE"/*.webp; do
  [ -f "$g" ] || continue
  case " $wanted " in *" ${g##*/} "*) ;; *) rm -f "$g"; echo "  removed stale $g";; esac
done

# ---- 3. RealiTea logo variants (transparent PNGs -> WebP with alpha) ----
# Served in this order by scripts/snowwhite.js as the reader scrolls: the logo
# fades in at the synopsis and gets progressively creepier toward the end.
LOGOS="realitea_green_red_leaves realitea_blue_white_leaves realitea_red_red_lightleaves realitea_green_white_red_eyes realitea_green_white_evil_eyes realitea_no_text_evilish_eyes"
mkdir -p "$OUTDIR/logo"
if [ "$have_cwebp" -eq 1 ]; then
  n=0
  for name in $LOGOS; do
    n=$((n+1)); src="$ASSETS/RealiTea_logos/$name.png"; dest="$OUTDIR/logo/$n.webp"
    [ -f "$src" ] || { echo "  warning: logo not found: $src"; continue; }
    [ -f "$dest" ] && [ ! "$src" -nt "$dest" ] || { make_webp "$src" "$dest" 700 82; echo "  converted $dest"; }
  done
  for g in "$OUTDIR"/logo/*.webp; do
    [ -f "$g" ] || continue
    k="${g##*/}"; k="${k%.webp}"
    [ "$k" -le "$n" ] 2>/dev/null || { rm -f "$g"; echo "  removed stale $g"; }
  done
fi
# ---- 4. Production photos -> the filmstrip at the top of the page ----
# Each master becomes two WebP derivatives keyed by the photographer's frame
# number (..._0129.jpg -> 0129), plus a manifest line carrying the original's
# pixel size so the strip can reserve each tile's width before the image loads.
# One glob with an extension switch, not *.jpg plus *.JPG: the Mac filesystem is
# case-insensitive, so both patterns would match the same file twice.
MANIFEST="$OUTDIR/show.js"
if [ ! -d "$SHOWPHOTOS" ]; then
  echo "note: show photo folder not found, leaving the filmstrip as it is: $SHOWPHOTOS"
elif [ "$have_cwebp" -eq 0 ]; then
  echo "note: skipping the production photos - they are only ever served as WebP."
else
  mkdir -p "$GALLERY/thumbs" "$GALLERY/web"
  tmp=$(mktemp -t snowwhite-show)
  printf '%s\n' "/* Auto-generated by build-snowwhite.sh from the show's photo folder - do not edit by hand. */" \
                "window.SNOWWHITE_PHOTOS = [" > "$tmp"
  shots=0
  shot_ids=""
  for src in "$SHOWPHOTOS"/*; do
    [ -f "$src" ] || continue
    case "${src##*.}" in jpg|JPG|jpeg|JPEG|png|PNG) ;; *) continue;; esac
    stem="${src##*/}"; stem="${stem%.*}"
    id="${stem##*_}"
    # no trailing frame number? fall back to a slug of the whole filename
    case "$id" in ''|*[!0-9]*) id=$(printf '%s' "$stem" | tr -C 'A-Za-z0-9' '-');; esac
    w=$(sips -g pixelWidth "$src" 2>/dev/null | awk '/pixelWidth/{print $2}')
    h=$(sips -g pixelHeight "$src" 2>/dev/null | awk '/pixelHeight/{print $2}')
    [ -n "$w" ] && [ -n "$h" ] || { echo "  warning: could not read the size of $src"; continue; }
    [ -f "$GALLERY/thumbs/$id.webp" ] && [ ! "$src" -nt "$GALLERY/thumbs/$id.webp" ] || \
      make_webp "$src" "$GALLERY/thumbs/$id.webp" "$STRIP_MAX" "$STRIP_QUALITY"
    [ -f "$GALLERY/web/$id.webp" ] && [ ! "$src" -nt "$GALLERY/web/$id.webp" ] || \
      make_webp "$src" "$GALLERY/web/$id.webp" "$FULL_MAX" "$FULL_QUALITY"
    printf '  { "id": "%s", "w": %s, "h": %s },\n' "$id" "$w" "$h" >> "$tmp"
    shot_ids="$shot_ids $id.webp"
    shots=$((shots+1))
  done
  printf '%s\n' "];" >> "$tmp"
  mv "$tmp" "$MANIFEST"

  # clear out derivatives whose master has been removed from the folder
  for d in "$GALLERY/thumbs" "$GALLERY/web"; do
    for g in "$d"/*.webp; do
      [ -f "$g" ] || continue
      case " $shot_ids " in *" ${g##*/} "*) ;; *) rm -f "$g"; echo "  removed stale $g";; esac
    done
  done
  echo "  Production photos: $shots"
fi

echo "Wrote $OUTDIR/people.js and $MANIFEST. Refresh snow-white.html."
