from __future__ import annotations

import os
import shutil
from pathlib import Path
import subprocess


def run_showcase_query(script_name: str, *, env: dict[str, str] | None = None) -> subprocess.CompletedProcess[str]:
    repo_root = Path(__file__).resolve().parents[1]
    full_env = os.environ.copy()
    if env:
        full_env.update(env)
    return subprocess.run(
        ["bash", f"showcase/queries/{script_name}"],
        cwd=repo_root,
        env=full_env,
        text=True,
        capture_output=True,
        check=False,
    )


def test_showcase_project_backlog_query_outputs_project_links() -> None:
    result = run_showcase_query("projects-with-open-todos.sh")

    assert result.returncode == 0, result.stderr
    assert "# Projects with open todos" in result.stdout
    assert "- [[/projects/blog-pipeline]]" in result.stdout
    assert "- [[/projects/vimwiki-query]]" in result.stdout


def test_showcase_active_projects_query_outputs_active_projects() -> None:
    result = run_showcase_query("active-projects.sh")

    assert result.returncode == 0, result.stderr
    assert "# Active projects" in result.stdout
    assert "- [[/projects/blog-pipeline]]" in result.stdout
    assert "- [[/projects/vimwiki-query]]" in result.stdout


def test_showcase_project_specific_todos_query_outputs_vimwiki_query_tasks() -> None:
    result = run_showcase_query("open-todos-for-vimwiki-query.sh")

    assert result.returncode == 0, result.stderr
    assert "# Open todos for /projects/vimwiki-query" in result.stdout
    assert "[[/diary/2026-03-17]] write cookbook examples for [[/projects/vimwiki-query]]" in result.stdout


def test_showcase_draft_blog_posts_query_outputs_drafts() -> None:
    result = run_showcase_query("draft-blog-posts.sh")

    assert result.returncode == 0, result.stderr
    assert "# Draft blog posts" in result.stdout
    assert "- [[/blog/plain-text-dashboards]]" in result.stdout


def test_showcase_blog_kanban_query_groups_posts_by_status() -> None:
    result = run_showcase_query("blog-kanban.sh")

    assert result.returncode == 0, result.stderr
    assert "## draft" in result.stdout
    assert "## review" in result.stdout
    assert "- [[/blog/plain-text-dashboards]]" in result.stdout
    assert "- [[/blog/project-rollups]]" in result.stdout


def test_showcase_people_with_open_followups_query_outputs_people_links() -> None:
    result = run_showcase_query("people-with-open-follow-ups.sh")

    assert result.returncode == 0, result.stderr
    assert "# People with open follow-ups" in result.stdout
    assert "- [[/people/Alice]]" in result.stdout
    assert "- [[/people/Bob]]" in result.stdout


def test_showcase_mentions_of_alice_query_outputs_diary_mentions() -> None:
    result = run_showcase_query("mentions-of-alice.sh")

    assert result.returncode == 0, result.stderr
    assert "# Mentions of /people/Alice" in result.stdout
    assert "[[/diary/2026-03-18]] ask [[/people/Alice]] for feedback on [[/blog/project-rollups]]" in result.stdout


def test_showcase_diary_mentions_of_project_query_outputs_diary_links() -> None:
    result = run_showcase_query("diary-mentions-vimwiki-query.sh")

    assert result.returncode == 0, result.stderr
    assert "# Diary mentions of /projects/vimwiki-query" in result.stdout
    assert "[[/diary/2026-03-17]] write cookbook examples for [[/projects/vimwiki-query]]" in result.stdout


def test_showcase_backlinks_query_outputs_pages_linking_to_project() -> None:
    result = run_showcase_query("backlinks-to-vimwiki-query.sh")

    assert result.returncode == 0, result.stderr
    assert "# Backlinks to projects/vimwiki-query.md" in result.stdout
    assert "- [[/diary/2026-03-17]]" in result.stdout


def test_showcase_orphan_pages_query_outputs_orphan_note() -> None:
    result = run_showcase_query("orphan-pages.sh")

    assert result.returncode == 0, result.stderr
    assert "# Orphan pages" in result.stdout
    assert "- [[/scratch/lonely-note]]" in result.stdout


def test_showcase_due_date_query_outputs_matching_tasks() -> None:
    result = run_showcase_query("tasks-due-2026-03-20.sh")

    assert result.returncode == 0, result.stderr
    assert "# Tasks due 2026-03-20" in result.stdout
    assert "[[/diary/2026-03-18]] send project recap to [[/people/Bob]] for [[/projects/vimwiki-query]]" in result.stdout


def test_showcase_context_query_outputs_matching_tasks() -> None:
    result = run_showcase_query("tasks-in-context-writing.sh")

    assert result.returncode == 0, result.stderr
    assert "# Tasks in @writing" in result.stdout
    assert "[[/diary/2026-03-17]] write cookbook examples for [[/projects/vimwiki-query]]" in result.stdout


def test_showcase_project_page_task_query_uses_inherited_frontmatter() -> None:
    result = run_showcase_query("open-tasks-from-project-pages.sh")

    assert result.returncode == 0, result.stderr
    assert "# Open tasks from project pages" in result.stdout
    assert "[[/projects/vimwiki-query]] collect backlink query ideas" in result.stdout


def test_showcase_section_backlinks_query_outputs_pages_linking_to_project_section() -> None:
    result = run_showcase_query("section-backlinks-vimwiki-query-next.sh")

    assert result.returncode == 0, result.stderr
    assert "# Backlinks to projects/vimwiki-query.md#next" in result.stdout
    assert "- [[/diary/2026-03-18]]" in result.stdout


def test_showcase_quest_board_query_emits_sections_and_cards() -> None:
    result = run_showcase_query("quest-board.sh")

    assert result.returncode == 0, result.stderr
    assert "# Quest Board" in result.stdout
    assert "## Needs Decision" in result.stdout
    assert "## Blocked" in result.stdout
    assert "## Waiting" in result.stdout
    assert "## Stale" in result.stdout
    assert "## Active" in result.stdout
    assert "## Recently Finished" in result.stdout
    assert "### [[/projects/blog-pipeline]]" in result.stdout
    assert "### [[/projects/vimwiki-query]]" in result.stdout
    assert "No waiting projects." in result.stdout


def test_showcase_quest_board_query_uses_card_fields_and_docs_example() -> None:
    repo_root = Path(__file__).resolve().parents[1]
    result = run_showcase_query("quest-board.sh")

    assert result.returncode == 0, result.stderr
    assert "Goal:" in result.stdout
    assert "Reason:" in result.stdout
    assert "Counts:" in result.stdout
    assert "Updated:" in result.stdout
    assert "Updated: 2026-03-20" in result.stdout
    assert "Updated: 2026-01-01" in result.stdout
    assert "bash showcase/queries/quest-board.sh" in (repo_root / "docs" / "cookbook.md").read_text(encoding="utf-8")


def test_showcase_quest_board_query_honors_injected_root_and_bin_paths(tmp_path: Path) -> None:
    repo_root = Path(__file__).resolve().parents[1]
    wiki_root = tmp_path / "custom-wiki"
    shutil.copytree(repo_root / "showcase" / "wiki", wiki_root)

    marker = tmp_path / "bin-called"
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    wrapper = bin_dir / "vimwiki-query"
    wrapper.write_text(
        "\n".join(
            [
                "#!/usr/bin/env bash",
                f"touch {marker}",
                f"exec {repo_root / 'bin' / 'vimwiki-query'} \"$@\"",
                "",
            ]
        ),
        encoding="utf-8",
    )
    wrapper.chmod(0o755)

    result = run_showcase_query(
        "quest-board.sh",
        env={
            "SHOWCASE_WIKI_ROOT": str(wiki_root),
            "VIMWIKI_QUERY_BIN": str(wrapper),
        },
    )

    assert result.returncode == 0, result.stderr
    assert marker.exists()
    assert "# Quest Board" in result.stdout
    assert "### [[/projects/quest-workflow]]" in result.stdout


def test_showcase_crm_dashboard_query_emits_sections_and_cards() -> None:
    result = run_showcase_query("crm-dashboard.sh")

    assert result.returncode == 0, result.stderr
    assert "# CRM Dashboard" in result.stdout
    assert "## Open follow-up" in result.stdout
    assert "## Waiting reply" in result.stdout
    assert "## Dormant" in result.stdout
    assert "### [[/people/Alice]]" in result.stdout
    assert "### [[/people/Bob]]" in result.stdout
    assert "No waiting reply contacts." in result.stdout
