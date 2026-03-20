#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/wiki"
TARGET='projects/vimwiki-query.md#next'

bin/vimwiki-query scan --root "$ROOT" --format json \
  | jq -r --arg target "$TARGET" '
      "# Backlinks to \($target)",
      (
        .headings
        | map(select((.page_id + "#" + .anchor) == $target))
        | .[0].inlinks[]
        | "- [[/" + (.rel_path | sub("\\.md$"; "")) + "]]"
      )
    '
