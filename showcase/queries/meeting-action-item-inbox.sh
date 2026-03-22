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
pages = [page for page in records if page.get("type") == "page" and page.get("frontmatter", {}).get("type") == "meeting"]
tasks_by_page: dict[str, list[str]] = defaultdict(list)
for task in [record for record in records if record.get("type") == "task"]:
    if task.get("completed"):
        continue
    page = task["page"]["rel_path"]
    if page in {meeting["rel_path"] for meeting in pages}:
        tasks_by_page[page].append(task["text"])

print("# Meeting Action-Item Inbox")
print()
for page in sorted(pages, key=lambda item: item["rel_path"]):
    tasks = tasks_by_page.get(page["rel_path"], [])
    if not tasks:
        continue
    print(f"## {rel_to_link(page['rel_path'])}")
    for text in tasks:
        print(f"- {text}")
    print()
if not tasks_by_page:
    print("No meeting action items found.")
PY
