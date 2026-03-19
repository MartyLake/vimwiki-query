from __future__ import annotations

from collections import defaultdict
from pathlib import Path

from vimwiki_query.discovery import discover_markdown_files
from vimwiki_query.parser import parse_markdown_file


def scan_wiki(root: Path | str) -> list[dict]:
    root_path = Path(root)
    records: list[dict] = []

    for rel_path in discover_markdown_files(root_path):
        records.extend(parse_markdown_file(root_path, rel_path))

    _attach_link_graph(records)
    return records


def _attach_link_graph(records: list[dict]) -> None:
    pages = {record["rel_path"]: record for record in records if record["type"] == "page"}
    outlinks_by_page: dict[str, set[str]] = defaultdict(set)
    inlinks_by_page: dict[str, set[str]] = defaultdict(set)

    for record in records:
        if record["type"] != "link" or not record.get("resolved"):
            continue

        source = record["page_id"]
        target = record["resolved_path"]
        outlinks_by_page[source].add(target)
        if target in pages:
            inlinks_by_page[target].add(source)

    for rel_path, page in pages.items():
        page["file"]["outlinks"] = sorted(outlinks_by_page.get(rel_path, set()))
        page["file"]["inlinks"] = sorted(inlinks_by_page.get(rel_path, set()))
