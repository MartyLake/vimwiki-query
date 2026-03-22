#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"
TMP_JSON="$(mktemp)"
trap 'rm -f "$TMP_JSON"' EXIT

"$VIMWIKI_QUERY_BIN" scan --root "$ROOT" --format ndjson > "$TMP_JSON"

python3 - "$TMP_JSON" <<'PY'
from __future__ import annotations

import json
import re
import sys
from collections import defaultdict
from datetime import datetime, timezone

DORMANT_DAYS = 90

source_path = sys.argv[1]
with open(source_path, "r", encoding="utf-8") as handle:
    records = [json.loads(line) for line in handle if line.strip()]

pages = [record for record in records if record["type"] == "page"]
tasks = [record for record in records if record["type"] == "task" and not record.get("completed", False)]

people_pages = {
    page["rel_path"]: page
    for page in pages
    if page.get("frontmatter", {}).get("type") == "person"
    and page.get("frontmatter", {}).get("status") != "archived"
}

link_re = re.compile(r"\[\[(/people/[^\]]+)\]\]")


def fmt_date(epoch: int) -> str:
    return datetime.fromtimestamp(epoch, tz=timezone.utc).strftime("%Y-%m-%d")


def person_key_from_link(raw: str) -> str:
    key = raw.split("#", 1)[0].lstrip("/")
    if not key.endswith(".md"):
        key = f"{key}.md"
    return key


def keys_for_task(task: dict) -> list[str]:
    keys: list[str] = []
    for match in link_re.findall(task.get("text", "")):
        key = person_key_from_link(match)
        if key in people_pages:
            keys.append(key)
    return keys


def task_rows(person_key: str) -> list[dict]:
    rows: list[dict] = []
    for task in tasks:
        page = task.get("page", {})
        if page.get("frontmatter", {}).get("type") == "person" and task["rel_path"] == person_key:
            rows.append(task)
            continue
        if person_key in keys_for_task(task):
            rows.append(task)
    return sorted(rows, key=lambda task: (task.get("rel_path", ""), int(task.get("line", 0)), task.get("id", "")))


def task_state(task: dict) -> str | None:
    tags = set(task.get("tags", []))
    if "waiting" in tags:
        return "waiting"
    return None


def classify(person_key: str) -> str:
    rows = task_rows(person_key)
    page = people_pages[person_key]
    last_contact = page.get("frontmatter", {}).get("last_contact")
    has_contact = bool(str(last_contact).strip()) if last_contact is not None else False
    has_open_followup = len(rows) > 0
    has_waiting = any(task_state(task) == "waiting" for task in rows)
    mtime = int(page["file"]["mtime"])
    age_days = int((datetime.now(timezone.utc) - datetime.fromtimestamp(mtime, tz=timezone.utc)).total_seconds() // 86400)

    if has_open_followup:
        return "Waiting reply" if has_waiting else "Open follow-up"
    if has_contact and age_days <= DORMANT_DAYS:
        return "Dormant"
    return "Dormant"


def reason_for(person_key: str, section: str) -> str:
    rows = task_rows(person_key)
    if section == "Open follow-up":
        if rows:
            return rows[0]["text"]
        return ""
    if section == "Waiting reply":
        for task in rows:
            if task_state(task) == "waiting":
                return task["text"]
        return ""
    return "No open follow-up."


sections = ["Open follow-up", "Waiting reply", "Dormant"]
by_section: dict[str, list[str]] = defaultdict(list)

for person_key in sorted(people_pages):
    by_section[classify(person_key)].append(person_key)

print("# CRM Dashboard")
print()

empty_message = {
    "Open follow-up": "No open follow-up contacts.",
    "Waiting reply": "No waiting reply contacts.",
    "Dormant": "No dormant contacts.",
}

for section in sections:
    print(f"## {section}")
    keys = sorted(by_section.get(section, []), key=lambda key: (int(people_pages[key]["file"]["mtime"]), key))
    if not keys:
        print(empty_message[section])
        print()
        continue

    for key in keys:
        page = people_pages[key]
        rows = task_rows(key)
        last_contact = page.get("frontmatter", {}).get("last_contact")
        print(f"### [[/{key.removesuffix('.md')}]]")
        print(f"- Status: {page.get('frontmatter', {}).get('status', 'active')}")
        if last_contact:
            print(f"- Last contact: {last_contact}")
        print(f"- Reason: {reason_for(key, section)}")
        print(f"- Counts: open {len(rows)}, waiting {sum(1 for task in rows if task_state(task) == 'waiting')}")
        print(f"- Updated: {fmt_date(int(page['file']['mtime']))}")
        print()
PY
