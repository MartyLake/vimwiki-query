#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/wiki"
TMP_JSON="$(mktemp)"
trap 'rm -f "$TMP_JSON"' EXIT

bin/vimwiki-query scan --root "$ROOT" --format ndjson > "$TMP_JSON"

python3 - "$TMP_JSON" <<'PY'
from __future__ import annotations

import json
import re
import sys
from collections import defaultdict
from datetime import datetime, timezone

RECENT_FINISHED_DAYS = 7
STALE_DAYS = 7

source_path = sys.argv[1]
with open(source_path, "r", encoding="utf-8") as handle:
    records = [json.loads(line) for line in handle if line.strip()]

pages = [record for record in records if record["type"] == "page"]
tasks = [record for record in records if record["type"] == "task" and not record.get("completed", False)]
links = [record for record in records if record["type"] == "link" and record.get("resolved")]

project_pages = {
    page["rel_path"]: page
    for page in pages
    if page.get("frontmatter", {}).get("type") == "project"
}

link_re = re.compile(r"\[\[(/projects/[^\]]+)\]\]")


def canonical_project_key(raw: str) -> str:
    key = raw.split("#", 1)[0].lstrip("/")
    if not key.endswith(".md"):
        key = f"{key}.md"
    return key


def task_state(task: dict) -> str | None:
    tags = set(task.get("tags", []))
    if "needs-decision" in tags:
        return "needs-decision"
    if "blocked" in tags:
        return "blocked"
    if tags.intersection({"wait", "waiting", "waitingfor"}):
        return "waiting"
    return None


def fmt_date(epoch: int) -> str:
    return datetime.fromtimestamp(epoch, tz=timezone.utc).strftime("%Y-%m-%d")


def wiki_path(rel_path: str) -> str:
    return f"[[/{rel_path.removesuffix('.md')}]]"


def project_keys_from_task(task: dict) -> list[str]:
    if task.get("page", {}).get("frontmatter", {}).get("type") == "project":
        return [task["rel_path"]]

    keys: list[str] = []
    for match in link_re.findall(task.get("text", "")):
        key = canonical_project_key(match)
        if key in project_pages:
            keys.append(key)
    return keys


def project_tasks(project_key: str) -> list[dict]:
    matched: list[dict] = []
    for task in tasks:
        if project_key in project_keys_from_task(task):
            matched.append(task)
    return sorted(
        matched,
        key=lambda task: (
            0 if task.get("page", {}).get("frontmatter", {}).get("type") == "project" else 1,
            task.get("rel_path", ""),
            int(task.get("line", 0)),
            task.get("id", ""),
        ),
    )


def unique_task_rows(project_key: str) -> list[dict]:
    seen: set[str] = set()
    rows: list[dict] = []
    for task in project_tasks(project_key):
        if task["id"] in seen:
            continue
        seen.add(task["id"])
        rows.append(task)
    return rows


def count_tasks(project_key: str, predicate) -> int:
    return sum(1 for task in unique_task_rows(project_key) if predicate(task))


def reason_task(project_key: str, section: str, rows: list[dict]) -> dict | None:
    if section == "Needs Decision":
        wanted = "needs-decision"
    elif section == "Blocked":
        wanted = "blocked"
    elif section == "Waiting":
        wanted = "waiting"
    else:
        wanted = None

    if wanted is not None:
        for task in rows:
            if task_state(task) == wanted:
                return task
        return None

    if section == "Active":
        project_next_step = project_pages[project_key].get("frontmatter", {}).get("next_step", "")
        if project_next_step:
            return {"text": project_next_step, "rel_path": project_key, "source_rank": 0}
        return rows[0] if rows else None

    if section == "Stale":
        project_next_step = project_pages[project_key].get("frontmatter", {}).get("next_step", "")
        if project_next_step:
            return {"text": project_next_step, "rel_path": project_key, "source_rank": 0}
        return {"text": "No recent project-page updates.", "rel_path": project_key, "source_rank": 0}

    return None


def render_reason(task: dict | None) -> str:
    if not task:
        return ""
    if task.get("source_rank", 0) == 1:
        return f"{wiki_path(task['rel_path'])} {task['text']}"
    return task["text"]


def classify(project_key: str) -> str | None:
    page = project_pages[project_key]
    status = page.get("frontmatter", {}).get("status", "")
    mtime = int(page["file"]["mtime"])
    age_days = int((datetime.now(timezone.utc) - datetime.fromtimestamp(mtime, tz=timezone.utc)).total_seconds() // 86400)
    rows = unique_task_rows(project_key)
    state_rows = [task for task in rows if task_state(task)]

    if status == "archived":
        return "Recently Finished" if age_days <= RECENT_FINISHED_DAYS else None
    if any(task_state(task) == "needs-decision" for task in rows):
        return "Needs Decision"
    if any(task_state(task) == "blocked" for task in rows):
        return "Blocked"
    if any(task_state(task) == "waiting" for task in rows):
        return "Waiting"
    if age_days > STALE_DAYS:
        return "Stale"
    if rows or str(page.get("frontmatter", {}).get("next_step", "")).strip():
        return "Active"
    return None


def section_message(section: str) -> str:
    return {
        "Needs Decision": "No projects need a decision.",
        "Blocked": "No blocked projects.",
        "Waiting": "No waiting projects.",
        "Stale": "No stale projects.",
        "Active": "No active projects.",
        "Recently Finished": "No recently finished projects.",
    }[section]


sections = [
    "Needs Decision",
    "Blocked",
    "Waiting",
    "Stale",
    "Active",
    "Recently Finished",
]

projects_by_section: dict[str, list[str]] = defaultdict(list)

for project_key in sorted(project_pages):
    section = classify(project_key)
    if section:
        projects_by_section[section].append(project_key)

print("# Quest Board")
print()

for section in sections:
    print(f"## {section}")
    project_keys = sorted(
        projects_by_section.get(section, []),
        key=lambda key: (int(project_pages[key]["file"]["mtime"]), key),
    )
    if not project_keys:
        print(section_message(section))
        print()
        continue

    for project_key in project_keys:
        page = project_pages[project_key]
        rows = unique_task_rows(project_key)
        reason = render_reason(reason_task(project_key, section, rows))
        counts = {
            "open": len(rows),
            "needs_decision": count_tasks(project_key, lambda task: task_state(task) == "needs-decision"),
            "blocked": count_tasks(project_key, lambda task: task_state(task) == "blocked"),
            "waiting": count_tasks(project_key, lambda task: task_state(task) == "waiting"),
        }

        print(f"### {wiki_path(project_key)}")
        if page.get("frontmatter", {}).get("goal"):
            print(f"- Goal: {page['frontmatter']['goal']}")
        if reason:
            print(f"- Reason: {reason}")
        print(
            f"- Counts: open {counts['open']}, needs-decision {counts['needs_decision']}, "
            f"blocked {counts['blocked']}, waiting {counts['waiting']}"
        )
        print(f"- Updated: {fmt_date(int(page['file']['mtime']))}")
        print()
PY
