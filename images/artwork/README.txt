Your artwork lives in two group folders:

  images/artwork/cartoons/    -> shown under "Cartoons" in Art & Cartoons
  images/artwork/paintings/   -> shown under "Paintings"

Drop images (PNG / JPG / GIF / WEBP, any filenames) into those folders, then
from the main site folder run:

    bash build-artwork.sh

That makes small thumbnails (in each folder's thumbs/ subfolder, via macOS's
built-in "sips") and rewrites manifest.js so each subsection shows its images
automatically. Clicking any image opens it full-size in a lightbox
(arrow keys / on-screen arrows to move, Esc to close).

Add another group later (e.g. "sketches"):
  1. add its name to ARTGROUPS in build-artwork.sh
  2. make the folder images/artwork/sketches/
  3. add <h3 class="subhead">Sketches</h3>
         <div class="gallery__grid" id="sketchesGrid"></div>  in index.html
  4. add { gridId: "sketchesGrid", group: "sketches" } to the galleries list in scripts/main.js
