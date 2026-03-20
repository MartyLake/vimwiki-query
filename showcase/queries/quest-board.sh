#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/wiki"
TMP_JSON="$(mktemp)"

trap 'rm -f "$TMP_JSON"' EXIT

bin/vimwiki-query scan --root "$ROOT" --format ndjson \
  > "$TMP_JSON"

python3 - "$ROOT" "$TMP_JSON" <<'PY'
import json
import re
import sys
from collections import defaultdict
from datetime import datetime, timezone

ROOT = sys.argv[1]
SOURCE = sys.argv[2]
RECENT_FINISHED_DAYS = 7
STALE_DAYS = 7

with open(SOURCE, "r", encoding="utf-8") as handle:
    records = [json.loads(line) for line in handle if line.strip()]
pages = [record for record in records if record["type"] == "page"]
tasks = [record for record in records if record["type"] == "task"]

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


def is_open_task(task: dict) -> bool:
    return not task.get("completed", False)


def task_state(task: dict) -> str | None:
    tags = set(task.get("tags", []))
    if "needs-decision" in tags:
        return "needs-decision"
    if "blocked" in tags:
        return "blocked"
    if tags.intersection({"wait", "waiting", "waitingfor"}):
        return "waiting"
    return None


def task_project_keys(task: dict) -> list[str]:
    page = task.get("page", {})
    if page.get("frontmatter", {}).get("type") == "project":
        return [page["rel_path"]]
    keys = []
    for match in link_re.findall(task.get("text", "")):
        key = canonical_project_key(match.lstrip("/"))
        if key.startswith("projects/"):
            keys.append(key)
    return keys


def task_source_rank(task: dict) -> int:
    return 0 if task.get("page", {}).get("frontmatter", {}).get("type") == "project" else 1


def project_tasks(project_key: str) -> list[dict]:
    matched = []
    for task in tasks:
        if not is_open_task(task):
            continue
        if project_key in task_project_keys(task):
            matched.append(task)
    return sorted(
        matched,
        key=lambda task: (
            task_source_rank(task),
            task.get("rel_path", ""),
            int(task.get("line", 0)),
            task.get("id", ""),
        ),
    )


def project_count(project_key: str, matcher) -> int:
    seen = set()
    for task in project_tasks(project_key):
        if matcher(task):
            seen.add(task["id"])
    return len(seen)


def first_reason(project_key: str, matcher=None, fallback=""):
    for task in project_tasks(project_key):
        if matcher is None or matcher(task):
            source = f"[[/" + task["rel_path"].removesuffix(".md") + "]]"
            text = task["text"]
            if task.get("page", {}).get("frontmatter", {}).get("type") == "project":
                return text
            return f"{source} {text}"
    return fallback


def fmt_date(epoch: int) -> str:
    return datetime.fromtimestamp(epoch, tz=timezone.utc).strftime("%Y-%m-%d")


def project_sort_key(page: dict):
    return (page["file"]["mtime"], page["rel_path"])


def classify(page: dict) -> str | None:
    key = page["rel_path"]
    fm = page.get("frontmatter", {})
    status = fm.get("status")
    mtime = int(page["file"]["mtime"])
    age_days = (datetime.now(timezone.utc) - datetime.fromtimestamp(mtime, tz=timezone.utc)).days

    tasks_for_project = project_tasks(key)

    if status == "archived":
        if age_days <= RECENT_FINISHED_DAYS:
            return "Recently Finished"
        return None

    if any(task_state(task) == "needs-decision" for task in tasks_for_project):
        return "Needs Decision"
    if any(task_state(task) == "blocked" for task in tasks_for_project):
        return "Blocked"
    if any(task_state(task) == "waiting" for task in tasks_for_project):
        return "Waiting"
    if age_days > STALE_DAYS:
        return "Stale"
    if tasks_for_project or str(fm.get("next_step", "")).strip():
        return "Active"
    return None


sections = [
    "Needs Decision",
    "Blocked",
    "Waiting",
    "Stale",
    "Active",
    "Recently Finished",
]

projects_by_section = defaultdict(list)

for page in sorted(project_pages.values(), key=project_sort_key):
    section = classify(page)
    if section is None:
        continue
    projects_by_section[section].append(page)

print("# Quest Board")
print()

empty_messages = {
    "Needs Decision": "No projects need a decision.",
    "Blocked": "No blocked projects.",
    "Waiting": "No waiting projects.",
    "Stale": "No stale projects.",
    "Active": "No active projects.",
    "Recently Finished": "No recently finished projects.",
}

for section in sections:
    print(f"## {section}")
    items = projects_by_section.get(section, [])
    if not items:
        print(empty_messages[section])
        print()
        continue

    for page in items:
        key = page["rel_path"]
        fm = page.get("frontmatter", {})
        project_link = f"[[/{key.removesuffix('.md')}]]"
        goal = fm.get("goal", "")
        next_step = fm.get("next_step", "")
        open_count = project_count(key, lambda task: True)
        needs_count = project_count(key, lambda task: task_state(task) == "needs-decision")
        blocked_count = project_count(key, lambda task: task_state(task) == "blocked")
        waiting_count = project_count(key, lambda task: task_state(task) == "waiting")
        updated = fmt_date(int(page["file"]["mtime"]))

        if section == "Needs Decision":
            reason = first_reason(key, lambda task: task_state(task) == "needs-decision")
        elif section == "Blocked":
            reason = first_reason(key, lambda task: task_state(task) == "blocked")
        elif section == "Waiting":
            reason = first_reason(key, lambda task: task_state(task) == "waiting")
        elif section == "Active":
            reason = next_step.strip() or first_reason(key)
        elif section == "Stale":
            reason = next_step.strip() or "No recent project-page updates."
        else:
            reason = ""

        print(f"### {project_link}")
        print(f"- Goal: {goal}")
        if reason:
            print(f"- Reason: {reason}")
        print(
            f"- Counts: open {open_count}, needs-decision {needs_count}, "
            f"blocked {blocked_count}, waiting {waiting_count}"
        )
        print(f"- Updated: {updated}")
        print()

PY
