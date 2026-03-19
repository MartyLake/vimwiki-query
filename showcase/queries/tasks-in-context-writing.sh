#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/wiki"
CONTEXT='writing'

bin/vimwiki-query scan --root "$ROOT" --format json \
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
