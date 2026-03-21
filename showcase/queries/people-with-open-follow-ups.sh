#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

"$VIMWIKI_QUERY_BIN" scan --root "$ROOT" --format ndjson \
  | jq -r -s '
      "# People with open follow-ups",
      (
        map(
          select(.type == "task" and (.completed | not))
          | .people_links = [
              (.text | scan("\\[\\[/people/[^]]+\\]\\]"))
              | sub("^\\[\\["; "")
              | sub("\\]\\]$"; "")
            ]
          | select((.people_links | length) > 0)
        )
        | map(.people_links[])
        | unique
        | .[]
        | "- [[" + . + "]]"
      )
    '
