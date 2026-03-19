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
    assert len(payload["pages"]) == 2
    assert len(payload["tasks"]) == 2
    assert payload["headings"][0]["type"] == "heading"
    assert payload["links"][0]["type"] == "link"


def test_scan_json_enriches_pages_with_link_graph_and_timestamps(run_cli, sample_wiki_root) -> None:
    result = run_cli("scan", "--root", str(sample_wiki_root), "--format", "json")

    assert result.returncode == 0, result.stderr

    payload = json.loads(result.stdout)
    pages = {page["rel_path"]: page for page in payload["pages"]}

    assert pages["index.md"]["file"]["outlinks"] == ["projects/roadmap.md"]
    assert pages["index.md"]["file"]["inlinks"] == ["projects/roadmap.md"]
    assert pages["projects/roadmap.md"]["file"]["outlinks"] == ["index.md"]
    assert pages["projects/roadmap.md"]["file"]["inlinks"] == ["index.md"]
    assert isinstance(pages["index.md"]["file"]["mtime"], int)
    assert isinstance(pages["index.md"]["file"]["ctime"], int)


def test_scan_rejects_missing_root(run_cli, sample_wiki_root) -> None:
    missing_root = sample_wiki_root / "missing"
    result = run_cli("scan", "--root", str(missing_root), "--format", "ndjson")

    assert result.returncode == 1
    assert "Root path does not exist" in result.stderr


def test_bin_launcher_runs_scan(run_bin_cli, sample_wiki_root) -> None:
    result = run_bin_cli("scan", "--root", str(sample_wiki_root), "--format", "ndjson")

    assert result.returncode == 0, result.stderr
    assert '"type": "page"' in result.stdout
