# Cookbook

## Past Diary Todos As Vimwiki Links

This query lists all open todos from diary files earlier than `2026-03-19`
and renders them as wiki-rooted Vimwiki links:

```sh
bin/vimwiki-query scan --root ~/Nextcloud/Vimrc/Wiki --format ndjson \
  | jq -r -s --arg current '2026-03-19' '
      "# All todos",
      (
        map(
          select(
            .type == "task"
            and (.completed | not)
            and (.rel_path | test("^diary/[0-9]{4}-[0-9]{2}-[0-9]{2}\\.md$"))
          )
          | .diary_date = (.rel_path | capture("^diary/(?<date>[0-9]{4}-[0-9]{2}-[0-9]{2})\\.md$").date)
          | select(.diary_date < $current)
        )
        | sort_by(.diary_date)
        | .[]
        | "- [[/" + (.rel_path | sub("\\.md$"; "")) + "]] " + .text
      )
    '
```

## Projects

### Active Projects

```sh
bin/vimwiki-query scan --root ~/Wiki --format ndjson \
  | jq -r -s '
      "# Active projects",
      (
        map(select(.type == "page" and .frontmatter.type == "project" and .frontmatter.status == "active"))
        | sort_by(.rel_path)
        | .[]
        | "- [[/" + (.rel_path | sub("\\.md$"; "")) + "]]"
      )
    '
```

### Projects With Open Todos

```sh
bin/vimwiki-query scan --root ~/Wiki --format ndjson \
  | jq -r -s '
      "# Projects with open todos",
      (
        map(
          select(.type == "task" and (.completed | not))
          | .project_links = [
              (.text | scan("\\[\\[/projects/[^]]+\\]\\]"))
              | sub("^\\[\\["; "")
              | sub("\\]\\]$"; "")
            ]
          | select((.project_links | length) > 0)
        )
        | map(.project_links[])
        | unique
        | .[]
        | "- [[" + . + "]]"
      )
    '
```

### Open Todos For One Project

```sh
PROJECT='/projects/vimwiki-query'
bin/vimwiki-query scan --root ~/Wiki --format ndjson \
  | jq -r -s --arg project "$PROJECT" '
      "# Open todos for \($project)",
      (
        map(
          select(.type == "task" and (.completed | not) and (.text | contains($project)))
        )
        | sort_by(.rel_path, .line)
        | .[]
        | "- [[/" + (.rel_path | sub("\\.md$"; "")) + "]] " + .text
      )
    '
```

### Backlinks To One Project

```sh
TARGET='projects/vimwiki-query.md'
bin/vimwiki-query scan --root ~/Wiki --format json \
  | jq -r --arg target "$TARGET" '
      "# Backlinks to \($target)",
      (
        .pages
        | map(select(.file.outlinks | index($target)))
        | sort_by(.rel_path)
        | .[]
        | "- [[/" + (.rel_path | sub("\\.md$"; "")) + "]]"
      )
    '
```

### Open Tasks From Project Pages

This uses task inheritance from the owning page frontmatter.

```sh
bin/vimwiki-query scan --root ~/Wiki --format json \
  | jq -r '
      "# Open tasks from project pages",
      (
        .tasks
        | map(select((.completed | not) and .page.frontmatter.type == "project"))
        | sort_by(.rel_path, .line)
        | .[]
        | "- [[/" + (.rel_path | sub("\\.md$"; "")) + "]] " + .text
      )
    '
```

## Blog Posts

### Draft Queue

```sh
bin/vimwiki-query scan --root ~/Wiki --format ndjson \
  | jq -r -s '
      "# Draft blog posts",
      (
        map(select(.type == "page" and .frontmatter.type == "blog-post" and .frontmatter.status == "draft"))
        | .[]
        | "- [[/" + (.rel_path | sub("\\.md$"; "")) + "]]"
      )
    '
```

### Kanban By Status

```sh
bin/vimwiki-query scan --root ~/Wiki --format ndjson \
  | jq -r -s '
      map(select(.type == "page" and .frontmatter.type == "blog-post"))
      | group_by(.frontmatter.status)
      | .[]
      | "## " + (.[0].frontmatter.status // "unknown"),
        (.[]
          | "- [[/" + (.rel_path | sub("\\.md$"; "")) + "]]"),
        ""
    '
```

## People

### People With Open Follow-Ups

Use links like `[[/people/Alice]]` or `[[/people/Bob]]` inside task text.

```sh
bin/vimwiki-query scan --root ~/Wiki --format ndjson \
  | jq -r -s '
      "# People with open follow-ups",
      (
        map(
          select(.type == "task" and (.completed | not))
          | .people_links = [
              (.text | scan("\\[\\[/people/[^]]+\\]\\]"))
              | sub("^\\[\\["; "")
              | sub("\\]\\]$"; "")
            ]
          | select((.people_links | length) > 0)
        )
        | map(.people_links[])
        | unique
        | .[]
        | "- [[" + . + "]]"
      )
    '
```

### Mentions Of One Person

```sh
PERSON='/people/Alice'
bin/vimwiki-query scan --root ~/Wiki --format ndjson \
  | jq -r -s --arg person "$PERSON" '
      "# Mentions of \($person)",
      (
        map(select((.type == "task" or .type == "page" or .type == "heading" or .type == "link") and (.text | contains($person))))
        | .[]
        | "- [[/" + (.rel_path | sub("\\.md$"; "")) + "]] " + .text
      )
    '
```

## Diary / Review

### Diary Mentions Of One Project

```sh
PROJECT='/projects/vimwiki-query'
bin/vimwiki-query scan --root ~/Wiki --format ndjson \
  | jq -r -s --arg project "$PROJECT" '
      "# Diary mentions of \($project)",
      (
        map(
          select(
            .type == "task"
            and (.rel_path | test("^diary/[0-9]{4}-[0-9]{2}-[0-9]{2}\\.md$"))
            and (.text | contains($project))
          )
        )
        | sort_by(.rel_path)
        | .[]
        | "- [[/" + (.rel_path | sub("\\.md$"; "")) + "]] " + .text
      )
    '
```

### Orphan Pages

```sh
bin/vimwiki-query scan --root ~/Wiki --format json \
  | jq -r '
      "# Orphan pages",
      (
        .pages
        | map(select((.file.inlinks | length) == 0 and (.file.outlinks | length) == 0))
        | sort_by(.rel_path)
        | .[]
        | "- [[/" + (.rel_path | sub("\\.md$"; "")) + "]]"
      )
    '
```

### Tasks Due On A Specific Date

```sh
DUE='2026-03-20'
bin/vimwiki-query scan --root ~/Wiki --format json \
  | jq -r --arg due "$DUE" '
      "# Tasks due \($due)",
      (
        .tasks
        | map(select(.due == $due))
        | sort_by(.rel_path, .line)
        | .[]
        | "- [[/" + (.rel_path | sub("\\.md$"; "")) + "]] " + .text
      )
    '
```

### Tasks In One GTD Context

```sh
CONTEXT='writing'
bin/vimwiki-query scan --root ~/Wiki --format json \
  | jq -r --arg context "$CONTEXT" '
      "# Tasks in @\($context)",
      (
        .tasks
        | map(select(.contexts | index($context)))
        | sort_by(.rel_path, .line)
        | .[]
        | "- [[/" + (.rel_path | sub("\\.md$"; "")) + "]] " + .text
      )
    '
```
