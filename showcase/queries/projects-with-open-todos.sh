#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/wiki"

bin/vimwiki-query scan --root "$ROOT" --format ndjson \
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
