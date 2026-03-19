from __future__ import annotations

import subprocess


def test_showcase_project_backlog_query_outputs_project_links() -> None:
    result = subprocess.run(
        ["bash", "showcase/queries/projects-with-open-todos.sh"],
        text=True,
        capture_output=True,
        check=False,
    )

    assert result.returncode == 0, result.stderr
    assert "# Projects with open todos" in result.stdout
    assert "- [[/projects/blog-pipeline]]" in result.stdout
    assert "- [[/projects/vimwiki-query]]" in result.stdout
