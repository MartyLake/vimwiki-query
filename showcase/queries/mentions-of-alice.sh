#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/wiki"
PERSON='/people/Alice'

bin/vimwiki-query scan --root "$ROOT" --format ndjson \
  | jq -r -s --arg person "$PERSON" '
      "# Mentions of \($person)",
      (
        map(select((.type == "task" or .type == "page" or .type == "heading" or .type == "link") and (.text | contains($person))))
        | .[]
        | "- [[/" + (.rel_path | sub("\\.md$"; "")) + "]] " + .text
      )
    '
