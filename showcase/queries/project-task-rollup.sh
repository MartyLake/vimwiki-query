#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

PROJECT="${PROJECT:-/projects/vimwiki-query}"
TMP_JSON="$(mktemp)"
trap 'rm -f "$TMP_JSON"' EXIT

"$VIMWIKI_QUERY_BIN" scan --root "$ROOT" --format json > "$TMP_JSON"

python3 - "$PROJECT" "$TMP_JSON" <<'PY'
from __future__ import annotations

import sys

from _lib import link_records_by_source, load_records, rel_to_link, target_to_rel

project = sys.argv[1].lstrip("/")
records = load_records(sys.argv[2])
page_fm = {page["rel_path"]: page.get("frontmatter", {}) for page in records if page.get("type") == "page"}
links_by_source = link_records_by_source(records)

def source_project_links(rel_path: str, line: int) -> list[str]:
    out = []
    for link in links_by_source.get((rel_path, line), []):
        target_rel = target_to_rel(link["target"])
        if target_rel == f"{project.removesuffix('.md')}.md":
            out.append(target_rel)
    return out

page_tasks = []
diary_tasks = []
for task in [record for record in records if record.get("type") == "task"]:
    if task.get("completed"):
        continue
    source = task["page"]["rel_path"]
    if source == project:
        page_tasks.append(task["text"])
    elif source.startswith("diary/"):
        if source_project_links(source, int(task["line"])):
            diary_tasks.append(f"[[/{source.removesuffix('.md')}]] {task['text']}")

print(f"# Task Rollup for {rel_to_link(project)}")
print()
print("## Project Page")
if page_tasks:
    for text in page_tasks:
        print(f"- {text}")
else:
    print("- No open project-page tasks.")
print()
print("## Diary Mentions")
if diary_tasks:
    for text in diary_tasks:
        print(f"- {text}")
else:
    print("- No open diary mentions.")
PY
