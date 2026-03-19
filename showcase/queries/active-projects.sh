#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/wiki"

bin/vimwiki-query scan --root "$ROOT" --format ndjson \
  | jq -r -s '
      "# Active projects",
      (
        map(select(.type == "page" and .frontmatter.type == "project" and .frontmatter.status == "active"))
        | sort_by(.rel_path)
        | .[]
        | "- [[/" + (.rel_path | sub("\\.md$"; "")) + "]]"
      )
    '
