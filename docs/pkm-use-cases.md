# PKM Use Cases

This memo tracks common PKM use-case categories across tools like Obsidian,
Logseq, Roam, RemNote, Notion, Tana, Heptabase, Capacities, Anytype, and
Org-mode, with a bias toward what fits a text-first `vimwiki-query` model.

## Current Coverage

The current scanner + `jq` cookbook already covers these categories well:

- task rollups across notes
- diary backlog review
- frontmatter-driven dashboards for projects, blog posts, and people
- backlinks, orphans, and section-aware backlinks
- GTD-style task filters via `due:`, `+project`, and `@context`
- grouped text-first dashboards and kanban-like outputs

## Missing Categories

The main categories that appear repeatedly across other PKM tools, but are not
yet showcased strongly here, are:

- weekly review dashboards
- waiting-on / blocked-work views
- meeting notes and action-item inboxes
- personal CRM / people follow-up pages
- research / reading / source pipelines
- unlinked-mention cleanup workflows
- calendar / habit / recurrence review
- learning / revisit / spaced-review workflows
- visual boards / canvases / whiteboards

The first six fit Vimwiki and `jq` naturally. The last three are weaker fits
because they depend more on time systems, repetition mechanics, or spatial UI.

## Strong Showcase Candidates

These are the most promising next showcase slices.

### Weekly Review Dashboard

One page that pulls together:

- diary entries from the current week
- open tasks due soon
- active projects not updated recently
- waiting-on follow-ups
- people or projects mentioned this week

This is one of the clearest "PKM command center" demos we could show.

### Waiting-On / Blocked Work

Tasks or project pages using frontmatter or task tokens like:

- `status: waiting`
- `status: blocked`
- `waiting-on: [[/people/Alice]]`
- `blocked-by: [[/projects/api-migration]]`

This would demonstrate GTD-style review without needing a custom task engine.

### Meeting Action-Item Inbox

A meeting note convention such as:

```yaml
---
type: meeting
with:
  - /people/Alice
project: /projects/vimwiki-query
---
```

combined with extracted unchecked tasks from meeting notes, grouped by person or
project.

### Project Health Dashboard

A richer project rollup showing:

- open task count
- last mention in diary
- due-soon tasks
- blocked tasks
- backlinks to key sections like `#Next`

This is probably the highest-value next showcase after the current project demos.

### Personal CRM

`person` pages can already work as lightweight CRM records. The next useful
showcase would surface:

- recent diary mentions of a person
- open tasks involving that person
- last-contact or follow-up dates from frontmatter

### Research / Source Inbox

Minimal source notes using frontmatter such as:

```yaml
---
type: source
status: inbox
topic: pkm
url: https://example.com
---
```

and queries like:

- unread sources
- sources per topic
- sources mentioned by a project
- notes that still need ingestion

### Unlinked Mention Cleanup

A weaker-but-interesting semantic layer beyond backlinks:

- notes mentioning a project or person without linking it
- diary entries that should probably link to an existing entity page

This is useful as wiki hygiene, though it is less core than review workflows.

## Patterns Worth Borrowing

These conventions show up across multiple PKM tools and fit plain Markdown well:

- frontmatter object typing with `type` and `status`
- wiki links as explicit relationships
- daily-note capture as the temporal spine of the system
- section anchors for long-note granularity
- relation-like fields in frontmatter:
  - `project`
  - `with`
  - `waiting-on`
  - `blocked-by`
  - `review`
  - `last_contact`
  - `url`
- saved or embedded queries as context-sensitive dashboards

## Where Other Tools Go Further

These are real categories, but not strong immediate targets for `vimwiki-query`:

- visual whiteboards and canvases
- flashcards / spaced repetition systems
- semantic AI search
- database-style rollups with editable UI controls
- drag-and-drop board interaction

They matter, but they are not the next low-regret path for a text-first Vimwiki
companion.

## Source Notes

- Obsidian emphasizes backlinks, daily notes, databases/bases, and canvas-based
  visual workspaces.
- Notion emphasizes relations, rollups, and multiple database views.
- Capacities emphasizes dynamic queries, block-based linking, and unlinked
  mentions.
- Tana emphasizes supertags, search nodes, daily notes, and field-driven
  objects.
- RemNote emphasizes backlinks, portals, tasks, and daily documents.
- Org-mode emphasizes agenda views, tags, search views, and time-oriented task
  workflows.

Official references:

- https://help.obsidian.md/plugins/backlinks
- https://help.obsidian.md/plugins/daily-notes
- https://help.obsidian.md/bases
- https://help.obsidian.md/plugins/canvas
- https://www.notion.com/help/relations-and-rollups
- https://docs.capacities.io/reference/queries
- https://docs.capacities.io/reference/unlinked-mentions
- https://docs.capacities.io/reference/dates-and-daily-notes
- https://tana.inc/docs/supertags
- https://tana.inc/docs/search-nodes
- https://tana.inc/docs/daily-notes
- https://help.remnote.com/en/articles/6030776-backlinks
- https://help.remnote.com/en/articles/6030742-portals
- https://help.remnote.com/en/articles/6752161-managing-tasks-with-todos
- https://help.remnote.com/en/articles/6752031-daily-documents
- https://orgmode.org/manual/Agenda-Views.html
- https://orgmode.org/manual/Tags.html
- https://orgmode.org/manual/Search-view.html
