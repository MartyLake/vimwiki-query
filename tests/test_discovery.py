from __future__ import annotations

from vimwiki_query.discovery import discover_markdown_files


def test_discover_markdown_files_returns_relative_paths(sample_wiki_root) -> None:
    paths = discover_markdown_files(sample_wiki_root)

    assert paths == ["index.md", "projects/duplicates.md", "projects/roadmap.md"]
