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
