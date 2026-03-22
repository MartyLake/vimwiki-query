from __future__ import annotations

import json
import re
from pathlib import Path

LINK_RE = re.compile(r"\[\[([^\]]+)\]\]")
PAGE_TARGET_RE = re.compile(r"^/?(.+?)(?:#.*)?$")


def load_records(path: str | Path) -> list[dict]:
    with open(path, "r", encoding="utf-8") as handle:
        content = handle.read().strip()
    if not content:
        return []
    if content.startswith("{"):
        data = json.loads(content)
        if isinstance(data, dict) and {"pages", "tasks", "headings", "links"} <= data.keys():
            return [
                *data.get("pages", []),
                *data.get("tasks", []),
                *data.get("headings", []),
                *data.get("links", []),
            ]
        return [data]
    return [json.loads(line) for line in content.splitlines() if line.strip()]


def rel_to_link(rel_path: str) -> str:
    return f"[[/{rel_path.removesuffix('.md')}]]"


def target_to_rel(target: str) -> str | None:
    if target.startswith(("http://", "https://", "www.")):
        return None
    target = target.split("|", 1)[0].strip()
    match = PAGE_TARGET_RE.match(target)
    if not match:
        return None
    rel_path = match.group(1).strip()
    if not rel_path:
        return None
    if rel_path.startswith("/"):
        rel_path = rel_path[1:]
    if rel_path.endswith("/"):
        rel_path = rel_path[:-1]
    if not rel_path.endswith(".md"):
        rel_path = f"{rel_path}.md"
    return rel_path


def link_targets(text: str) -> list[str]:
    return [match.group(1) for match in LINK_RE.finditer(text)]


def page_type_map(records: list[dict]) -> dict[str, str]:
    return {
        record["rel_path"]: record.get("frontmatter", {}).get("type", "")
        for record in records
        if record.get("type") == "page"
    }


def page_frontmatter_map(records: list[dict]) -> dict[str, dict]:
    return {
        record["rel_path"]: record.get("frontmatter", {})
        for record in records
        if record.get("type") == "page"
    }


def link_records_by_source(records: list[dict]) -> dict[tuple[str, int], list[dict]]:
    by_source: dict[tuple[str, int], list[dict]] = {}
    for record in records:
        if record.get("type") != "link":
            continue
        key = (record["rel_path"], int(record["line"]))
        by_source.setdefault(key, []).append(record)
    return by_source


def is_diary_page(rel_path: str) -> bool:
    return rel_path.startswith("diary/")

