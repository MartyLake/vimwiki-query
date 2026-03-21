#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

"$VIMWIKI_QUERY_BIN" scan --root "$ROOT" --format ndjson \
  | jq -r -s '
      "# Active projects",
      (
        map(select(.type == "page" and .frontmatter.type == "project" and .frontmatter.status == "active"))
        | sort_by(.rel_path)
        | .[]
        | "- [[/" + (.rel_path | sub("\\.md$"; "")) + "]]"
      )
    '
