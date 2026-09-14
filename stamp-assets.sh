#!/usr/bin/env bash
# Append ?v=<content hash> to every local stylesheet/script reference in the
# HTML so browsers (phones especially) refetch an asset as soon as it changes,
# instead of serving a cached copy for the rest of GitHub Pages' max-age.
# Runs from the pre-commit hook; safe to rerun by hand: bash stamp-assets.sh
set -euo pipefail
cd "$(dirname "$0")"

for html in *.html; do
  # local href/src values ending in .css or .js, with or without an existing ?v=
  grep -oE '(href|src)="[^"?:]+\.(css|js)(\?v=[0-9a-f]+)?"' "$html" | sort -u | while IFS= read -r attr; do
    path=$(printf '%s' "$attr" | sed -E 's/^(href|src)="([^"?]+).*/\2/')
    [ -f "$path" ] || continue
    hash=$(git hash-object "$path" | cut -c1-8)
    new=$(printf '%s' "$attr" | sed -E "s/=\"([^\"?]+)(\?v=[0-9a-f]+)?\"/=\"\1?v=$hash\"/")
    [ "$attr" = "$new" ] && continue
    sed -i '' "s#$attr#$new#g" "$html"
    echo "  $html: $path -> v=$hash"
  done
done
