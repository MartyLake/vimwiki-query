from __future__ import annotations

import re
import posixpath
from pathlib import Path, PurePosixPath


FRONTMATTER_DELIMITER = "---"
HEADING_RE = re.compile(r"^(#{1,6})\s+(.*\S)\s*$")
TASK_RE = re.compile(r"^(\s*)[-*]\s+\[([ xX.])\]\s+(.*)$")
INLINE_TAG_RE = re.compile(r"(?<!\w)#([A-Za-z0-9_-]+)")
WIKILINK_RE = re.compile(r"\[\[([^\]]+)\]\]")
MARKDOWN_LINK_RE = re.compile(r"(?<!!)\[([^\]]+)\]\(([^)]+)\)")
EXTERNAL_LINK_RE = re.compile(r"^(?:[a-zA-Z][a-zA-Z0-9+.-]*:|www\.)")
DATE_RE = re.compile(r"\b(\d{2,4}-\d{2}-\d{2})\b")
DUE_RE = re.compile(r"\bdue:(\d{2,4}-\d{2}-\d{2})\b")
PROJECT_RE = re.compile(r"(?:^|\s)\+([^\s]+)")
CONTEXT_RE = re.compile(r"(?:^|\s)@([^\s]+)")


def parse_markdown_file(root: Path | str, rel_path: str) -> list[dict]:
    root_path = Path(root)
    abs_path = root_path / rel_path
    raw_text = abs_path.read_text(encoding="utf-8")
    lines = raw_text.splitlines()
    stat_result = abs_path.stat()

    frontmatter, body_start = _parse_frontmatter(lines)
    title = _resolve_title(frontmatter, lines[body_start:], Path(rel_path).stem)
    page_tags = _normalize_tags(frontmatter.get("tags", []))
    file_info = _build_file_info(rel_path, title, page_tags, stat_result.st_ctime, stat_result.st_mtime)
    page_info = _build_page_info(rel_path, abs_path, title, page_tags, frontmatter)

    records: list[dict] = [
        {
            "type": "page",
            "id": rel_path,
            "page_id": rel_path,
            "parent_id": None,
            "path": str(abs_path),
            "rel_path": rel_path,
            "line": 1,
            "text": title,
            "tags": page_tags,
            "frontmatter": frontmatter,
            "file": {**file_info, "inlinks": [], "outlinks": []},
        }
    ]

    in_code_fence = False
    current_section = title
    section_stack: list[dict[str, object]] = []
    previous_anchors: dict[str, int] = {}

    for index, line in enumerate(lines, start=1):
        stripped = line.strip()
        if stripped.startswith("```"):
            in_code_fence = not in_code_fence
            continue

        if in_code_fence:
            continue

        heading_match = HEADING_RE.match(line)
        if heading_match:
            level = len(heading_match.group(1))
            heading_text = heading_match.group(2)
            current_section = heading_text
            anchor = _normalize_anchor(heading_text) or f"heading-{index}"
            while section_stack and int(section_stack[-1]["level"]) >= level:
                section_stack.pop()
            parent_section_id = str(section_stack[-1]["id"]) if section_stack else None
            anchor_unique = _make_unique_anchor(anchor, previous_anchors)
            section_path = [str(entry["anchor_unique"]) for entry in section_stack] + [anchor_unique]
            complete_anchor = "#".join(section_path)
            heading_id = f"{rel_path}#heading:{index}"
            section_stack.append(
                {
                    "id": heading_id,
                    "level": level,
                    "anchor": anchor,
                    "anchor_unique": anchor_unique,
                }
            )
            records.append(
                {
                    "type": "heading",
                    "id": heading_id,
                    "page_id": rel_path,
                    "parent_id": parent_section_id,
                    "path": str(abs_path),
                    "rel_path": rel_path,
                    "line": index,
                    "text": heading_text,
                    "tags": page_tags,
                    "level": level,
                    "anchor": anchor,
                    "anchor_unique": anchor_unique,
                    "section_path": section_path,
                    "complete_anchor": complete_anchor,
                    "file": file_info,
                }
            )

        task_match = TASK_RE.match(line)
        if task_match:
            marker = task_match.group(2)
            raw_task_text = task_match.group(3)
            status, completed = _task_status(marker)
            due = _extract_due_date(raw_task_text)
            records.append(
                {
                    "type": "task",
                    "id": f"{rel_path}#task:{index}",
                    "page_id": rel_path,
                    "parent_id": None,
                    "path": str(abs_path),
                    "rel_path": rel_path,
                    "line": index,
                    "text": _strip_inline_tags(raw_task_text),
                    "raw": line.strip(),
                    "status": status,
                    "completed": completed,
                    "tags": _extract_inline_tags(raw_task_text),
                    "due": due,
                    "dates": _extract_dates(raw_task_text, due),
                    "projects": _extract_gtd_projects(raw_task_text),
                    "contexts": _extract_gtd_contexts(raw_task_text),
                    "section": current_section,
                    "file": file_info,
                    "page": page_info,
                }
            )

        for match in WIKILINK_RE.finditer(line):
            target = match.group(1)
            target_anchor = _extract_target_anchor(target)
            is_external = _is_external_target(target)
            resolved_path = target if is_external else _resolve_wikilink(rel_path, target)
            resolved_complete_anchor = _normalize_anchor_reference(target_anchor)
            records.append(
                {
                    "type": "link",
                    "id": f"{rel_path}#link:{index}:{target}",
                    "page_id": rel_path,
                    "parent_id": None,
                    "path": str(abs_path),
                    "rel_path": rel_path,
                    "line": index,
                    "text": target,
                    "tags": page_tags,
                    "target": target,
                    "target_anchor": target_anchor,
                    "is_external": is_external,
                    "resolved_anchor": _normalize_anchor(target_anchor) if target_anchor and "#" not in target_anchor else _extract_last_anchor_segment(resolved_complete_anchor),
                    "resolved_complete_anchor": resolved_complete_anchor,
                    "resolved_path": resolved_path,
                    "resolved": False if is_external else (root_path / resolved_path).is_file(),
                    "file": file_info,
                }
            )

        for match in MARKDOWN_LINK_RE.finditer(line):
            text = match.group(1)
            target = match.group(2)
            target_anchor = _extract_target_anchor(target)
            is_external = _is_external_target(target)
            resolved_path = target if is_external else _resolve_wikilink(rel_path, target)
            resolved_complete_anchor = _normalize_anchor_reference(target_anchor)
            records.append(
                {
                    "type": "link",
                    "id": f"{rel_path}#link:{index}:{text}",
                    "page_id": rel_path,
                    "parent_id": None,
                    "path": str(abs_path),
                    "rel_path": rel_path,
                    "line": index,
                    "text": text,
                    "tags": page_tags,
                    "target": target,
                    "target_anchor": target_anchor,
                    "is_external": is_external,
                    "resolved_anchor": _normalize_anchor(target_anchor) if target_anchor and "#" not in target_anchor else _extract_last_anchor_segment(resolved_complete_anchor),
                    "resolved_complete_anchor": resolved_complete_anchor,
                    "resolved_path": resolved_path,
                    "resolved": False if is_external else (root_path / resolved_path).is_file(),
                    "file": file_info,
                }
            )

    return records


def _parse_frontmatter(lines: list[str]) -> tuple[dict, int]:
    if not lines or lines[0].strip() != FRONTMATTER_DELIMITER:
        return {}, 0

    frontmatter: dict[str, object] = {}
    index = 1
    current_list_key: str | None = None

    while index < len(lines):
        line = lines[index]
        stripped = line.strip()

        if stripped == FRONTMATTER_DELIMITER:
            return frontmatter, index + 1

        if not stripped:
            index += 1
            continue

        if stripped.startswith("- ") and current_list_key:
            value = stripped[2:].strip()
            frontmatter.setdefault(current_list_key, [])
            assert isinstance(frontmatter[current_list_key], list)
            frontmatter[current_list_key].append(value)
            index += 1
            continue

        current_list_key = None
        if ":" in line:
            key, raw_value = line.split(":", 1)
            key = key.strip()
            value = raw_value.strip()
            if value:
                frontmatter[key] = value
            else:
                frontmatter[key] = []
                current_list_key = key

        index += 1

    return {}, 0


def _resolve_title(frontmatter: dict, body_lines: list[str], fallback: str) -> str:
    frontmatter_title = frontmatter.get("title")
    if isinstance(frontmatter_title, str) and frontmatter_title:
        return frontmatter_title

    for line in body_lines:
        match = HEADING_RE.match(line)
        if match:
            return match.group(2)

    return fallback


def _build_file_info(rel_path: str, title: str, page_tags: list[str], ctime: float, mtime: float) -> dict:
    path = Path(rel_path)
    folder = "" if str(path.parent) == "." else str(path.parent)
    return {
        "name": path.name,
        "stem": path.stem,
        "folder": folder,
        "path": rel_path,
        "title": title,
        "tags": page_tags,
        "ctime": int(ctime),
        "mtime": int(mtime),
    }


def _build_page_info(rel_path: str, abs_path: Path, title: str, page_tags: list[str], frontmatter: dict) -> dict:
    return {
        "rel_path": rel_path,
        "path": str(abs_path),
        "title": title,
        "tags": page_tags,
        "frontmatter": frontmatter,
    }


def _normalize_tags(value: object) -> list[str]:
    if isinstance(value, list):
        return [str(item) for item in value]
    if isinstance(value, str) and value:
        return [value]
    return []


def _task_status(marker: str) -> tuple[str, bool]:
    if marker in {"x", "X"}:
        return "done", True
    if marker == ".":
        return "partial", False
    return "open", False


def _extract_inline_tags(text: str) -> list[str]:
    return [match.group(1) for match in INLINE_TAG_RE.finditer(text)]


def _strip_inline_tags(text: str) -> str:
    return INLINE_TAG_RE.sub("", text).strip()


def _extract_due_date(text: str) -> str | None:
    match = DUE_RE.search(text)
    if match:
        return match.group(1)
    return None


def _extract_dates(text: str, due: str | None) -> list[str]:
    matches = [match.group(1) for match in DATE_RE.finditer(text)]
    if due is None:
        return matches
    return [value for value in matches if value != due]


def _extract_gtd_projects(text: str) -> list[str]:
    return [match.group(1) for match in PROJECT_RE.finditer(text)]


def _extract_gtd_contexts(text: str) -> list[str]:
    return [match.group(1) for match in CONTEXT_RE.finditer(text)]


def _extract_target_anchor(target: str) -> str | None:
    if "#" not in target:
        return None
    _, anchor = target.split("#", 1)
    return anchor or None


def _resolve_wikilink(current_rel_path: str, target: str) -> str:
    target_path = target.split("#", 1)[0]
    if target_path.startswith("/"):
        base = PurePosixPath(target_path[1:])
    else:
        base = PurePosixPath(current_rel_path).parent / target_path

    resolved = base if base.suffix else PurePosixPath(f"{base}.md")
    normalized = posixpath.normpath(resolved.as_posix())
    return normalized if normalized != "." else ""


def _normalize_anchor(value: str | None) -> str | None:
    if value is None:
        return None
    normalized = value.strip().lower()
    normalized = re.sub(r"[^\w\s-]", "", normalized)
    normalized = re.sub(r"[-\s]+", "-", normalized)
    return normalized.strip("-") or None


def _make_unique_anchor(anchor: str | None, previous_anchors: dict[str, int]) -> str | None:
    if anchor is None:
        return None
    if anchor in previous_anchors:
        previous_anchors[anchor] += 1
        return f"{anchor}-{previous_anchors[anchor]}"
    previous_anchors[anchor] = 1
    return anchor


def _normalize_anchor_reference(value: str | None) -> str | None:
    if value is None:
        return None
    segments = [_normalize_anchor(segment) for segment in value.split("#")]
    filtered = [segment for segment in segments if segment]
    if not filtered:
        return None
    return "#".join(filtered)


def _extract_last_anchor_segment(value: str | None) -> str | None:
    if value is None:
        return None
    return value.split("#")[-1]


def _is_external_target(target: str) -> bool:
    return bool(EXTERNAL_LINK_RE.match(target))
