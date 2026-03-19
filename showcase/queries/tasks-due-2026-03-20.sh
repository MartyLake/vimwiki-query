#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/wiki"
DUE='2026-03-20'

bin/vimwiki-query scan --root "$ROOT" --format json \
  | jq -r --arg due "$DUE" '
      "# Tasks due \($due)",
      (
        .tasks
        | map(select(.due == $due))
        | sort_by(.rel_path, .line)
        | .[]
        | "- [[/" + (.rel_path | sub("\\.md$"; "")) + "]] " + .text
      )
    '
