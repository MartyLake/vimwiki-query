#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"
TARGET='projects/vimwiki-query.md'

"$VIMWIKI_QUERY_BIN" scan --root "$ROOT" --format json \
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
