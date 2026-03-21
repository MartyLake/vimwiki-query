#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

"$VIMWIKI_QUERY_BIN" scan --root "$ROOT" --format ndjson \
  | jq -r -s '
      "# Projects with open todos",
      (
        map(
          select(.type == "task" and (.completed | not))
          | .project_links = [
              (.text | scan("\\[\\[/projects/[^]]+\\]\\]"))
              | sub("^\\[\\["; "")
              | sub("\\]\\]$"; "")
            ]
          | select((.project_links | length) > 0)
        )
        | map(.project_links[])
        | unique
        | .[]
        | "- [[" + . + "]]"
      )
    '
