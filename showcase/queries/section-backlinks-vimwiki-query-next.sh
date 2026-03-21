#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"
TARGET='projects/vimwiki-query.md#next'

"$VIMWIKI_QUERY_BIN" scan --root "$ROOT" --format json \
  | jq -r --arg target "$TARGET" '
      "# Backlinks to \($target)",
      (
        .headings
        | map(select((.page_id + "#" + .anchor) == $target))
        | .[0].inlinks[]
        | "- [[/" + (.rel_path | sub("\\.md$"; "")) + "]]"
      )
    '
