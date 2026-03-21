#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"
DUE='2026-03-20'

"$VIMWIKI_QUERY_BIN" scan --root "$ROOT" --format json \
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
