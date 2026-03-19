from __future__ import annotations

import subprocess


def run_showcase_query(script_name: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["bash", f"showcase/queries/{script_name}"],
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
