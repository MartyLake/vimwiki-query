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
    headings = [record for record in records if record["type"] == "heading"]
    outlinks_by_page: dict[str, set[str]] = defaultdict(set)
    inlinks_by_page: dict[str, set[str]] = defaultdict(set)
    section_inlinks: dict[str, list[dict[str, object]]] = defaultdict(list)
    headings_by_target: dict[tuple[str, str], list[dict]] = defaultdict(list)

    for heading in headings:
        heading["inlinks"] = []
        anchor = heading.get("anchor")
        if anchor:
            headings_by_target[(heading["page_id"], anchor)].append(heading)

    for record in records:
        if record["type"] != "link" or not record.get("resolved"):
            continue

        source = record["page_id"]
        target = record["resolved_path"]
        outlinks_by_page[source].add(target)
        if target in pages:
            inlinks_by_page[target].add(source)

        resolved_anchor = record.get("resolved_anchor")
        if not resolved_anchor:
            continue

        candidate_headings = headings_by_target.get((target, resolved_anchor), [])
        if len(candidate_headings) != 1:
            record["resolved_section_id"] = None
            continue

        target_heading = candidate_headings[0]
        record["resolved_section_id"] = target_heading["id"]
        section_inlinks[target_heading["id"]].append(
            {
                "source_id": record["id"],
                "page_id": source,
                "rel_path": record["rel_path"],
                "line": record["line"],
            }
        )

    for rel_path, page in pages.items():
        page["file"]["outlinks"] = sorted(outlinks_by_page.get(rel_path, set()))
        page["file"]["inlinks"] = sorted(inlinks_by_page.get(rel_path, set()))

    for heading in headings:
        heading["inlinks"] = sorted(
            section_inlinks.get(heading["id"], []),
            key=lambda item: (str(item["rel_path"]), int(item["line"]), str(item["source_id"])),
        )
