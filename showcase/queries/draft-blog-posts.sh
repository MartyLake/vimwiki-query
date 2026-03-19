#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/wiki"

bin/vimwiki-query scan --root "$ROOT" --format ndjson \
  | jq -r -s '
      "# Draft blog posts",
      (
        map(select(.type == "page" and .frontmatter.type == "blog-post" and .frontmatter.status == "draft"))
        | .[]
        | "- [[/" + (.rel_path | sub("\\.md$"; "")) + "]]"
      )
    '
