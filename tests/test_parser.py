from __future__ import annotations

from vimwiki_query.parser import parse_markdown_file


def test_parse_markdown_file_emits_page_record_with_frontmatter_title(sample_wiki_root) -> None:
    records = parse_markdown_file(sample_wiki_root, "projects/roadmap.md")

    page = next(record for record in records if record["type"] == "page")

    assert page["id"] == "projects/roadmap.md"
    assert page["text"] == "Roadmap"
    assert page["file"]["title"] == "Roadmap"
    assert page["file"]["folder"] == "projects"
    assert page["tags"] == ["project"]


def test_parse_markdown_file_emits_task_records_with_status_and_context(sample_wiki_root) -> None:
    records = parse_markdown_file(sample_wiki_root, "projects/roadmap.md")

    tasks = [record for record in records if record["type"] == "task"]

    assert [task["status"] for task in tasks] == ["open", "done"]
    assert tasks[0]["completed"] is False
    assert tasks[0]["section"] == "Roadmap"
    assert tasks[0]["file"]["title"] == "Roadmap"
    assert tasks[0]["tags"] == ["active"]
    assert tasks[0]["due"] == "2026-03-20"
    assert tasks[0]["dates"] == ["2026-03-21"]
    assert tasks[0]["projects"] == ["vimwiki-query"]
    assert tasks[0]["contexts"] == ["work"]
    assert tasks[0]["page"]["frontmatter"]["title"] == "Roadmap"
    assert tasks[0]["page"]["rel_path"] == "projects/roadmap.md"
    assert "mtime" in tasks[0]["file"]
    assert "ctime" in tasks[0]["file"]


def test_parse_markdown_file_emits_heading_and_link_records(sample_wiki_root) -> None:
    records = parse_markdown_file(sample_wiki_root, "index.md")

    headings = [record for record in records if record["type"] == "heading"]
    links = [record for record in records if record["type"] == "link"]

    assert len(headings) == 1
    assert headings[0]["type"] == "heading"
    assert headings[0]["id"] == "index.md#heading:7"
    assert headings[0]["page_id"] == "index.md"
    assert headings[0]["rel_path"] == "index.md"
    assert headings[0]["line"] == 7
    assert headings[0]["text"] == "Welcome"
    assert headings[0]["tags"] == ["wiki"]
    assert headings[0]["level"] == 1
    assert headings[0]["file"]["title"] == "Home"
    assert headings[0]["file"]["path"] == "index.md"
    assert links[0]["target"] == "projects/roadmap"
    assert links[0]["resolved_path"] == "projects/roadmap.md"
    assert links[0]["resolved"] is True
    assert links[1]["target_anchor"] == "Next Steps"
    assert links[1]["resolved_anchor"] == "next-steps"
    assert links[1]["resolved"] is True


def test_parse_markdown_file_resolves_relative_and_absolute_vimwiki_links(sample_wiki_root) -> None:
    records = parse_markdown_file(sample_wiki_root, "projects/roadmap.md")

    links = [record for record in records if record["type"] == "link"]

    assert [link["resolved_path"] for link in links] == ["projects/index.md", "index.md"]
    assert links[0]["resolved"] is False
    assert links[1]["resolved"] is True


def test_parse_markdown_file_emits_section_identity_for_headings(sample_wiki_root) -> None:
    records = parse_markdown_file(sample_wiki_root, "projects/roadmap.md")

    headings = [record for record in records if record["type"] == "heading"]

    assert headings[0]["anchor"] == "roadmap"
    assert headings[0]["section_path"] == ["roadmap"]
    assert headings[1]["anchor"] == "next-steps"
    assert headings[1]["section_path"] == ["roadmap", "next-steps"]


def test_parse_markdown_file_handles_duplicate_heading_anchors(sample_wiki_root) -> None:
    records = parse_markdown_file(sample_wiki_root, "projects/duplicates.md")

    headings = [record for record in records if record["type"] == "heading"]

    assert headings[0]["anchor"] == "dup-root"
    assert headings[0]["anchor_unique"] == "dup-root"
    assert headings[1]["anchor"] == "same-heading"
    assert headings[1]["anchor_unique"] == "same-heading"
    assert headings[1]["complete_anchor"] == "dup-root#same-heading"
    assert headings[2]["anchor"] == "same-heading"
    assert headings[2]["anchor_unique"] == "same-heading-2"
    assert headings[2]["complete_anchor"] == "dup-root#same-heading-2"
