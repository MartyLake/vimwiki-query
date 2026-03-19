#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/wiki"
PROJECT='/projects/vimwiki-query'

bin/vimwiki-query scan --root "$ROOT" --format ndjson \
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
