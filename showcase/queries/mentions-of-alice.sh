#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"
PERSON='/people/Alice'

"$VIMWIKI_QUERY_BIN" scan --root "$ROOT" --format ndjson \
  | jq -r -s --arg person "$PERSON" '
      "# Mentions of \($person)",
      (
        map(select((.type == "task" or .type == "page" or .type == "heading" or .type == "link") and (.text | contains($person))))
        | .[]
        | "- [[/" + (.rel_path | sub("\\.md$"; "")) + "]] " + .text
      )
    '
