#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

"$VIMWIKI_QUERY_BIN" scan --root "$ROOT" --format ndjson \
  | jq -r -s '
      map(select(.type == "page" and .frontmatter.type == "blog-post"))
      | sort_by(.frontmatter.status, .rel_path)
      | group_by(.frontmatter.status)
      | .[]
      | "## " + (.[0].frontmatter.status // "unknown"),
        (.[]
          | "- [[/" + (.rel_path | sub("\\.md$"; "")) + "]]"),
        ""
    '
