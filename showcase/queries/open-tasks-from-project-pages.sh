#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

"$VIMWIKI_QUERY_BIN" scan --root "$ROOT" --format json \
  | jq -r '
      "# Open tasks from project pages",
      (
        .tasks
        | map(select((.completed | not) and .page.frontmatter.type == "project"))
        | sort_by(.rel_path, .line)
        | .[]
        | "- [[/" + (.rel_path | sub("\\.md$"; "")) + "]] " + .text
      )
    '
