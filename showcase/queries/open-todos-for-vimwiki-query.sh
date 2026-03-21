#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"
PROJECT='/projects/vimwiki-query'

"$VIMWIKI_QUERY_BIN" scan --root "$ROOT" --format ndjson \
  | jq -r -s --arg project "$PROJECT" '
      "# Open todos for \($project)",
      (
        map(select(.type == "task" and (.completed | not) and (.text | contains($project))))
        | sort_by(.rel_path, .line)
        | .[]
        | "- [[/" + (.rel_path | sub("\\.md$"; "")) + "]] " + .text
      )
    '
