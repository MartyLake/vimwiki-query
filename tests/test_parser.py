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


def test_parse_markdown_file_emits_heading_and_link_records(sample_wiki_root) -> None:
    records = parse_markdown_file(sample_wiki_root, "index.md")

    headings = [record for record in records if record["type"] == "heading"]
    links = [record for record in records if record["type"] == "link"]

    assert headings == [
        {
            "type": "heading",
            "id": "index.md#heading:7",
            "page_id": "index.md",
            "parent_id": None,
            "path": str(sample_wiki_root / "index.md"),
            "rel_path": "index.md",
            "line": 7,
            "text": "Welcome",
            "tags": ["wiki"],
            "level": 1,
            "file": {
                "name": "index.md",
                "stem": "index",
                "folder": "",
                "path": "index.md",
                "title": "Home",
                "tags": ["wiki"],
            },
        }
    ]
    assert links[0]["target"] == "projects/roadmap"
