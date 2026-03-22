#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

TMP_JSON="$(mktemp)"
trap 'rm -f "$TMP_JSON"' EXIT

"$VIMWIKI_QUERY_BIN" scan --root "$ROOT" --format json > "$TMP_JSON"

python3 - "$TMP_JSON" <<'PY'
from __future__ import annotations

import sys
from collections import defaultdict

from _lib import load_records, rel_to_link

records = load_records(sys.argv[1])
pages = [page for page in records if page.get("type") == "page" and page.get("frontmatter", {}).get("type") == "source"]
pages.sort(key=lambda page: (0 if page.get("frontmatter", {}).get("status") == "inbox" else 1 if page.get("frontmatter", {}).get("status") == "reading" else 2, page["file"]["mtime"], page["rel_path"]))

print("# Research Source Inbox")
print()

by_status: dict[str, list[dict]] = defaultdict(list)
for page in pages:
    by_status[page.get("frontmatter", {}).get("status", "unknown")].append(page)

for status in ["inbox", "reading"]:
    print(f"## {status.capitalize()}")
    rows = by_status.get(status, [])
    if not rows:
        print(f"- No {status} sources.")
        print()
        continue
    for page in sorted(rows, key=lambda item: (item["file"]["mtime"], item["rel_path"])):
        fm = page.get("frontmatter", {})
        extra = [f"status {status}"]
        if fm.get("topic"):
            extra.append(f"topic {fm['topic']}")
        if fm.get("url"):
            extra.append(f"url {fm['url']}")
        print(f"- {rel_to_link(page['rel_path'])} | " + " | ".join(extra))
    print()
PY
