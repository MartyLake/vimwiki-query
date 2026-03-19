#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/wiki"

bin/vimwiki-query scan --root "$ROOT" --format ndjson \
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
