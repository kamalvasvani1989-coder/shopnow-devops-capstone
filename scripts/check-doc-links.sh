#!/bin/bash
# Lists every relative link in the Markdown docs that points to a file that does not exist.
cd "$(dirname "$0")/.." || exit 1
rc=0
for md in README.md START-HERE.md docs/*.md; do
  dir=$(dirname "$md")
  grep -oE '\]\([^)#]+' "$md" | sed 's/^](//' | grep -v '^http' | while read -r l; do
    [ -e "$dir/$l" ] || echo "MISSING in $md: $l"
  done
done
grep -ohE 'evidence/[A-Za-z0-9._-]+\.txt' README.md docs/*.md | sort -u | while read -r f; do
  [ -e "docs/$f" ] || echo "MISSING evidence file referenced in text: docs/$f"
done
echo "link check done"
