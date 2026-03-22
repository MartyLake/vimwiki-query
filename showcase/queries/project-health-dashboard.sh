#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

TODAY="${TODAY:-2026-03-20}"
TMP_JSON="$(mktemp)"
trap 'rm -f "$TMP_JSON"' EXIT

"$VIMWIKI_QUERY_BIN" scan --root "$ROOT" --format json > "$TMP_JSON"

python3 - "$TODAY" "$TMP_JSON" <<'PY'
from __future__ import annotations

import datetime as dt
import sys

from _lib import link_records_by_source, load_records, rel_to_link, target_to_rel

today = dt.date.fromisoformat(sys.argv[1])
records = load_records(sys.argv[2])
pages = [record for record in records if record.get("type") == "page"]
tasks = [record for record in records if record.get("type") == "task"]
page_fm = {page["rel_path"]: page.get("frontmatter", {}) for page in pages}
links_by_source = link_records_by_source(records)

def task_state(task: dict) -> str:
    tags = set(task.get("tags", []))
    if "needs-decision" in tags:
        return "needs-decision"
    if "blocked" in tags:
        return "blocked"
    if tags.intersection({"wait", "waiting", "waitingfor"}):
        return "waiting"
    return "open"

def source_project_links(rel_path: str, line: int) -> list[str]:
    links = []
    for link in links_by_source.get((rel_path, line), []):
        target_rel = target_to_rel(link["target"])
        if target_rel and page_fm.get(target_rel, {}).get("type") == "project":
            links.append(target_rel)
    return links

project_rows: dict[str, dict] = {}
for page in pages:
    if page.get("frontmatter", {}).get("type") != "project":
        continue
    if page.get("frontmatter", {}).get("status") == "archived":
        continue
    project_rows[page["rel_path"]] = {
        "page": page,
        "tasks": {},
        "mentions": {},
    }

for task in tasks:
    source = task["page"]["rel_path"]
    if task_state(task) != "open":
        continue
    task_projects = []
    if page_fm.get(source, {}).get("type") == "project":
        task_projects.append(source)
    task_projects.extend(source_project_links(source, int(task["line"])))
    for project in dict.fromkeys(task_projects):
        if project in project_rows:
            project_rows[project]["tasks"][task["id"]] = task

for link in [record for record in records if record.get("type") == "link"]:
    source = link["rel_path"]
    if not source.startswith("diary/"):
        continue
    target_rel = target_to_rel(link["target"])
    if target_rel in project_rows:
        project_rows[target_rel]["mentions"][link["id"]] = link

def is_due_soon(due: str | None) -> bool:
    if not due:
        return False
    due_date = dt.date.fromisoformat(due)
    return today <= due_date <= today + dt.timedelta(days=7)

rows = []
for rel, data in project_rows.items():
    tasks_here = data["tasks"]
    tasks_here_values = list(tasks_here.values())
    due_soon = sum(1 for task in tasks_here_values if is_due_soon(task.get("due")))
    waiting_blocked = sum(1 for task in tasks_here_values if task_state(task) in {"waiting", "blocked"})
    rows.append(
        {
            "rel": rel,
            "status": data["page"].get("frontmatter", {}).get("status", "unknown"),
            "open": len(tasks_here_values),
            "due": due_soon,
            "wb": waiting_blocked,
            "mentions": len(data["mentions"]),
            "mtime": data["page"]["file"]["mtime"],
        }
    )

rows.sort(key=lambda row: (-row["wb"], -row["due"], -row["open"], row["mtime"], row["rel"]))

print("# Project Health Dashboard")
print()
for row in rows:
    print(
        f"- {rel_to_link(row['rel'])} | status {row['status']} | open {row['open']} | "
        f"due-soon {row['due']} | waiting/blocked {row['wb']} | diary mentions {row['mentions']} | "
        f"updated {dt.datetime.fromtimestamp(row['mtime']).date().isoformat()}"
    )
PY
