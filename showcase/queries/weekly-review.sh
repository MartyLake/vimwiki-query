#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

WEEK="${WEEK:-2026-W12}"
TMP_JSON="$(mktemp)"
trap 'rm -f "$TMP_JSON"' EXIT

"$VIMWIKI_QUERY_BIN" scan --root "$ROOT" --format json > "$TMP_JSON"

python3 - "$WEEK" "$TMP_JSON" <<'PY'
from __future__ import annotations

import datetime as dt
import sys

from _lib import is_diary_page, link_records_by_source, load_records, rel_to_link, target_to_rel

week = sys.argv[1]
records = load_records(sys.argv[2])
pages = {page["rel_path"]: page.get("frontmatter", {}) for page in records if page.get("type") == "page"}
page_types = {rel: fm.get("type", "") for rel, fm in pages.items()}
links_by_source = link_records_by_source(records)

def parse_iso_week(value: str) -> tuple[int, int]:
    year, week_num = value.split("-W")
    return int(year), int(week_num)

def in_week(date_str: str, target: str) -> bool:
    y, w = parse_iso_week(target)
    date = dt.date.fromisoformat(date_str)
    iso = date.isocalendar()
    return iso.year == y and iso.week == w

def section(title: str, items: list[str], empty: str) -> None:
    print(f"## {title}")
    if items:
        for item in items:
            print(f"- {item}")
    else:
        print(f"- {empty}")
    print()

open_diary: dict[str, str] = {}
done_diary: dict[str, str] = {}
project_mentions: dict[str, str] = {}
people_mentions: dict[str, str] = {}
due_this_week = []
updated_non_diary = []
active_not_updated = []

tasks = [record for record in records if record.get("type") == "task"]
pages = [record for record in records if record.get("type") == "page"]
links = [record for record in records if record.get("type") == "link"]

for task in tasks:
    page = task["page"]["rel_path"]
    if is_diary_page(page) and in_week(page[6:16], week):
        if not task["completed"]:
            open_diary[task["id"]] = f"[[/{page.removesuffix('.md')}]] {task['text']}"
        else:
            done_diary[task["id"]] = f"[[/{page.removesuffix('.md')}]] {task['text']}"
    due = task.get("due")
    if due and in_week(due, week):
        due_this_week.append(f"[[/{page.removesuffix('.md')}]] {task['text']}")

for link in links:
    source = link["rel_path"]
    if not is_diary_page(source) or not in_week(source[6:16], week):
        continue
    target_rel = target_to_rel(link["target"])
    if not target_rel:
        continue
    if page_types.get(target_rel) == "project":
        project_mentions[link["id"]] = rel_to_link(target_rel)
    if page_types.get(target_rel) == "person":
        people_mentions[link["id"]] = rel_to_link(target_rel)

for page in pages:
    rel = page["rel_path"]
    if is_diary_page(rel):
        continue
    mtime = dt.datetime.fromtimestamp(page["file"]["mtime"]).date()
    if in_week(mtime.isoformat(), week):
        updated_non_diary.append(rel_to_link(rel))
    elif page.get("frontmatter", {}).get("type") == "project" and page.get("frontmatter", {}).get("status") != "archived":
        active_not_updated.append(rel_to_link(rel))

print(f"# Weekly Review {week}")
print()
section("Open Diary Tasks", list(open_diary.values()), "No open diary tasks this week.")
section("Done This Week", list(done_diary.values()), "No done diary tasks this week.")
section("Project Mentions", sorted(set(project_mentions.values())), "No project mentions this week.")
section("People Mentions", sorted(set(people_mentions.values())), "No people mentions this week.")
section("Due This Week", due_this_week, "No tasks due this week.")
section("Active Projects Not Updated This Week", sorted(set(active_not_updated)), "No active projects are stale this week.")
section("Updated Notes Outside Diary", sorted(set(updated_non_diary)), "No non-diary notes updated this week.")
PY
