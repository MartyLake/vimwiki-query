#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/wiki"
PROJECT='/projects/vimwiki-query'

bin/vimwiki-query scan --root "$ROOT" --format ndjson \
  | jq -r -s --arg project "$PROJECT" '
      "# Open todos for \($project)",
      (
        map(select(.type == "task" and (.completed | not) and (.text | contains($project))))
        | sort_by(.rel_path, .line)
        | .[]
        | "- [[/" + (.rel_path | sub("\\.md$"; "")) + "]] " + .text
      )
    '
