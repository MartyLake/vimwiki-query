#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/wiki"

bin/vimwiki-query scan --root "$ROOT" --format ndjson \
  | jq -r -s '
      map(select(.type == "page" and .frontmatter.type == "blog-post"))
      | sort_by(.frontmatter.status, .rel_path)
      | group_by(.frontmatter.status)
      | .[]
      | "## " + (.[0].frontmatter.status // "unknown"),
        (.[]
          | "- [[/" + (.rel_path | sub("\\.md$"; "")) + "]]"),
        ""
    '
