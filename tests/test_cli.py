from __future__ import annotations

import json


def test_scan_ndjson_emits_page_and_task_records(run_cli, sample_wiki_root) -> None:
    result = run_cli("scan", "--root", str(sample_wiki_root), "--format", "ndjson")

    assert result.returncode == 0, result.stderr

    records = [json.loads(line) for line in result.stdout.splitlines() if line.strip()]

    assert any(record["type"] == "page" for record in records)
    assert any(record["type"] == "task" for record in records)


def test_scan_json_groups_records_by_type(run_cli, sample_wiki_root) -> None:
    result = run_cli("scan", "--root", str(sample_wiki_root), "--format", "json")

    assert result.returncode == 0, result.stderr

    payload = json.loads(result.stdout)

    assert list(payload) == ["pages", "tasks", "headings", "links"]
    assert len(payload["pages"]) == 3
    assert len(payload["tasks"]) == 2
    assert payload["headings"][0]["type"] == "heading"
    assert payload["links"][0]["type"] == "link"


def test_scan_json_enriches_pages_with_link_graph_and_timestamps(run_cli, sample_wiki_root) -> None:
    result = run_cli("scan", "--root", str(sample_wiki_root), "--format", "json")

    assert result.returncode == 0, result.stderr

    payload = json.loads(result.stdout)
    pages = {page["rel_path"]: page for page in payload["pages"]}

    assert pages["index.md"]["file"]["outlinks"] == ["projects/duplicates.md", "projects/roadmap.md"]
    assert pages["index.md"]["file"]["inlinks"] == ["projects/roadmap.md"]
    assert pages["projects/roadmap.md"]["file"]["outlinks"] == ["index.md"]
    assert pages["projects/roadmap.md"]["file"]["inlinks"] == ["index.md"]
    assert isinstance(pages["index.md"]["file"]["mtime"], int)
    assert isinstance(pages["index.md"]["file"]["ctime"], int)


def test_scan_json_enriches_headings_with_anchor_backlinks(run_cli, sample_wiki_root) -> None:
    result = run_cli("scan", "--root", str(sample_wiki_root), "--format", "json")

    assert result.returncode == 0, result.stderr

    payload = json.loads(result.stdout)
    headings = {heading["id"]: heading for heading in payload["headings"]}
    next_steps = headings["projects/roadmap.md#heading:12"]

    assert next_steps["anchor"] == "next-steps"
    assert next_steps["inlinks"] == [
        {
            "page_id": "index.md",
            "rel_path": "index.md",
            "line": 10,
            "source_id": "index.md#link:10:projects/roadmap#Next Steps",
        }
    ]


def test_scan_json_resolves_long_form_duplicate_heading_links(run_cli, sample_wiki_root) -> None:
    result = run_cli("scan", "--root", str(sample_wiki_root), "--format", "json")

    assert result.returncode == 0, result.stderr

    payload = json.loads(result.stdout)
    headings = {heading["id"]: heading for heading in payload["headings"]}
    links = {link["id"]: link for link in payload["links"]}

    first_duplicate = headings["projects/duplicates.md#heading:3"]
    second_duplicate = headings["projects/duplicates.md#heading:7"]
    first_link = links["index.md#link:11:projects/duplicates#Dup Root#Same Heading"]
    second_link = links["index.md#link:12:projects/duplicates#Dup Root#Same Heading-2"]

    assert first_link["resolved_section_id"] == first_duplicate["id"]
    assert second_link["resolved_section_id"] == second_duplicate["id"]
    assert first_duplicate["inlinks"] == [
        {
            "page_id": "index.md",
            "rel_path": "index.md",
            "line": 11,
            "source_id": "index.md#link:11:projects/duplicates#Dup Root#Same Heading",
        }
    ]
    assert second_duplicate["inlinks"] == [
        {
            "page_id": "index.md",
            "rel_path": "index.md",
            "line": 12,
            "source_id": "index.md#link:12:projects/duplicates#Dup Root#Same Heading-2",
        }
    ]


def test_scan_rejects_missing_root(run_cli, sample_wiki_root) -> None:
    missing_root = sample_wiki_root / "missing"
    result = run_cli("scan", "--root", str(missing_root), "--format", "ndjson")

    assert result.returncode == 1
    assert "Root path does not exist" in result.stderr


def test_bin_launcher_runs_scan(run_bin_cli, sample_wiki_root) -> None:
    result = run_bin_cli("scan", "--root", str(sample_wiki_root), "--format", "ndjson")

    assert result.returncode == 0, result.stderr
    assert '"type": "page"' in result.stdout
