#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"
CONTEXT='writing'

"$VIMWIKI_QUERY_BIN" scan --root "$ROOT" --format json \
  | jq -r --arg context "$CONTEXT" '
      "# Tasks in @\($context)",
      (
        .tasks
        | map(select(.contexts | index($context)))
        | sort_by(.rel_path, .line)
        | .[]
        | "- [[/" + (.rel_path | sub("\\.md$"; "")) + "]] " + .text
      )
    '
