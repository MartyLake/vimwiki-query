#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"
PROJECT='/projects/vimwiki-query'

"$VIMWIKI_QUERY_BIN" scan --root "$ROOT" --format ndjson \
  | jq -r -s --arg project "$PROJECT" '
      "# Diary mentions of \($project)",
      (
        map(
          select(
            .type == "task"
            and (.rel_path | test("^diary/[0-9]{4}-[0-9]{2}-[0-9]{2}\\.md$"))
            and (.text | contains($project))
          )
        )
        | sort_by(.rel_path)
        | .[]
        | "- [[/" + (.rel_path | sub("\\.md$"; "")) + "]] " + .text
      )
    '
