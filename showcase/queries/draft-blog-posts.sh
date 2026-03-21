#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

"$VIMWIKI_QUERY_BIN" scan --root "$ROOT" --format ndjson \
  | jq -r -s '
      "# Draft blog posts",
      (
        map(select(.type == "page" and .frontmatter.type == "blog-post" and .frontmatter.status == "draft"))
        | .[]
        | "- [[/" + (.rel_path | sub("\\.md$"; "")) + "]]"
      )
    '
