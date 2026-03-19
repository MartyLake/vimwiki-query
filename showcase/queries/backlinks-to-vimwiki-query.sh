#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/wiki"
TARGET='projects/vimwiki-query.md'

bin/vimwiki-query scan --root "$ROOT" --format json \
  | jq -r --arg target "$TARGET" '
      "# Backlinks to \($target)",
      (
        .pages
        | map(select(.file.outlinks | index($target)))
        | sort_by(.rel_path)
        | .[]
        | "- [[/" + (.rel_path | sub("\\.md$"; "")) + "]]"
      )
    '
