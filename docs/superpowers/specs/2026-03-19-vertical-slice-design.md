# Vimwiki Query JSON Atom Design

Date: 2026-03-19

## Goal

Build the first useful vertical slice of `vimwiki-query` by producing structured wiki data that can be queried with `jq`, rather than starting with a custom DSL or SQLite index.

This slice should prove three things:

- a thin parser can extract useful page and task data from Markdown-syntax Vimwiki files
- the extracted data can be represented in a stable, denormalized schema
- `jq` can provide most of the first-wave Dataview-style querying power on top of that schema

The product framing for this slice is not "Dataview clone". It is:

- structured wiki data
- Unix-friendly query pipelines
- Vim integration later through a thin shell-out layer

## Scope

Included in this slice:

- repository scaffold for a Python CLI
- executable launcher at `bin/vimwiki-query`
- Python package under `python/vimwiki_query/`
- Markdown file discovery under a provided wiki root
- thin parsing for page and task records
- denormalized typed atom output
- `ndjson` output as the canonical machine format
- `json` output as a grouped convenience format
- tests for discovery, parsing, and output shape
- documentation with example `jq` queries

Explicitly out of scope:

- SQLite or any persistent index
- a custom query DSL
- a `dataviewjs` equivalent
- native `vimwiki` syntax support
- automatic background indexing
- advanced rendering inside Vim

## Recommended Approach

The first implementation slice should be:

- `scan --root ... --format ndjson`
- `scan --root ... --format json`
- a small, stable atom schema designed to make LLM-generated `jq` queries easy

Why this shape:

- it gives useful output faster than a database-backed architecture
- it avoids premature query-language design
- it makes the hardest problem explicit: the extracted data model
- it leverages existing tooling instead of rebuilding filtering, projection, and sorting immediately

Alternatives considered and rejected:

- SQLite-first indexing was better aligned with the original handoff, but too heavy for this sidestep
- pure grep output was too lossy and unstable for reliable querying
- a Markdown AST/tree JSON shape was too document-oriented and awkward for cross-file queries

## Architecture

The slice has one primary executable surface: a parser-oriented CLI.

### CLI Surface

The CLI is the system. It lives under `python/vimwiki_query/` with a launcher at `bin/vimwiki-query`.

Initial commands:

- `vimwiki-query scan --root /path/to/wiki --format ndjson`
- `vimwiki-query scan --root /path/to/wiki --format json`

`scan` responsibilities:

- validate the root path
- discover Markdown wiki files
- parse each file into typed records
- emit records in a stable schema
- fail cleanly with short text errors

`scan` is intentionally stateless in this slice. Every invocation rescans the root.

### Query Layer

`jq` is the intended first query engine.

This means the project does not need to own filtering, sorting, grouping, flattening, or projection in the first slice. Instead, it should:

- provide data that is easy to query
- document example `jq` pipelines
- leave room for later wrappers or a dedicated DSL if the product evolves that way

`jq` should be treated as an expected companion tool for advanced querying in this slice.

### Vim Integration

Vim integration is deferred to a later slice, but the design should preserve a thin integration path:

- Vim shells out to the CLI
- Vim can optionally pipe the output through `jq`
- Vim renders text or structured results without owning parser logic

The parser and schema should not depend on Vim.

## Canonical Data Model

The parser should emit denormalized typed atoms.

Why denormalized:

- most queries are cross-cutting rather than tree-walking
- LLM-generated `jq` is more reliable when common context is repeated on each record
- users should not need joins for common task/page queries

Why atoms:

- `jq` filters homogeneous records naturally
- streaming remains possible
- grouped JSON can be derived from the same underlying records

### Canonical Transport

The canonical machine format should be `ndjson`.

Each line is one atom. This keeps the output streamable and Unix-friendly.

The CLI should also support a grouped `json` mode for debugging, examples, and whole-result processing. That grouped mode should be derived from the same atom stream.

### Record Types

MVP record types:

- `page`
- `task`
- `heading`
- `link`

`list_item` can wait until later unless it falls out naturally from task parsing.

### Common Fields

Every record should include these fields when meaningful:

- `type`
- `id`
- `page_id`
- `parent_id`
- `path`
- `rel_path`
- `line`
- `text`
- `tags`
- `file`

The `file` object should be repeated deliberately:

- `file.name`
- `file.stem`
- `file.folder`
- `file.path`
- `file.title`
- `file.tags`

This duplication is intentional. The goal is easy querying, not relational purity.

### Page Record

A `page` record should carry file-level metadata:

- page identity
- resolved title
- frontmatter object
- page tags
- file context

Example:

```json
{
  "type": "page",
  "id": "projects/roadmap.md",
  "page_id": "projects/roadmap.md",
  "parent_id": null,
  "path": "/wiki/projects/roadmap.md",
  "rel_path": "projects/roadmap.md",
  "line": 1,
  "text": "Roadmap",
  "tags": ["project", "active"],
  "frontmatter": {
    "title": "Roadmap"
  },
  "file": {
    "name": "roadmap.md",
    "stem": "roadmap",
    "folder": "projects",
    "path": "projects/roadmap.md",
    "title": "Roadmap",
    "tags": ["project", "active"]
  }
}
```

### Task Record

A `task` record should duplicate enough page context to make filtering easy:

- task identity
- owning page identity
- parent task identity when nested
- line number
- raw and normalized text
- explicit status fields
- section
- task tags
- repeated file context

Example:

```json
{
  "type": "task",
  "id": "projects/roadmap.md#task:12",
  "page_id": "projects/roadmap.md",
  "parent_id": null,
  "path": "/wiki/projects/roadmap.md",
  "rel_path": "projects/roadmap.md",
  "line": 12,
  "text": "ship the parser MVP",
  "raw": "- [ ] ship the parser MVP #active",
  "status": "open",
  "completed": false,
  "tags": ["active"],
  "section": "Roadmap",
  "file": {
    "name": "roadmap.md",
    "stem": "roadmap",
    "folder": "projects",
    "path": "projects/roadmap.md",
    "title": "Roadmap",
    "tags": ["project"]
  }
}
```

### Link And Heading Records

These records should follow the same denormalized principle:

- carry `page_id`
- include `line`
- include repeated `file` context
- carry record-specific fields such as heading level or link target

The exact schema for these can remain narrow in the first slice, but it should be documented and tested.

## Parsing Rules

The parser should stay intentionally narrow and explicit.

Markdown MVP responsibilities:

- discover `.md` files
- detect YAML frontmatter only when it appears at file start
- resolve title by frontmatter title, then first heading, then file stem
- extract inline tags outside fenced code blocks
- extract Markdown headings
- extract Markdown task items with indentation and section context
- extract simple Vimwiki-compatible Markdown links such as `[[Page]]`

The parser should not attempt perfect Vimwiki parity. The point is to emit useful structured data for the Markdown-first MVP.

## Output Modes

### `ndjson`

This is the canonical output.

Characteristics:

- one record per line
- easy to stream
- easy to pipe to `jq`
- easy to combine with Unix tools

### `json`

This is a grouped convenience format derived from the same records.

Suggested shape:

```json
{
  "pages": [...],
  "tasks": [...],
  "headings": [...],
  "links": [...]
}
```

This format is useful for:

- debugging
- documentation examples
- whole-result `jq` operations using grouped arrays
- LLM prompting when one structured document is easier than a stream

## Example Query Style

The project should document example `jq` queries as part of the user story.

Examples this schema should support comfortably:

- open tasks:

```sh
vimwiki-query scan --root ~/vimwiki --format ndjson \
  | jq -s 'map(select(.type == "task" and (.completed | not)))'
```

- pages tagged `project`:

```sh
vimwiki-query scan --root ~/vimwiki --format ndjson \
  | jq -s 'map(select(.type == "page" and (.tags | index("project"))))'
```

- task text and file title:

```sh
vimwiki-query scan --root ~/vimwiki --format ndjson \
  | jq -s 'map(select(.type == "task")) | map({task: .text, file: .file.title})'
```

This is enough to validate that the schema supports LLM-generated `jq` for common Dataview-like needs.

## Error Handling

Errors should remain simple and shell-friendly.

Requirements:

- invalid root path returns non-zero with a short message
- malformed frontmatter or parse issues should produce short record- or file-level errors
- internal exceptions should not print full tracebacks by default

If parse recovery is cheap, the CLI may skip bad files and report them on stderr, but the behavior must be documented and tested.

## Testing Strategy

This slice is test-first and parser-centric.

Required tests:

- discovery finds Markdown files under nested folders
- frontmatter at the top of file is parsed correctly
- title resolution follows the defined precedence
- task extraction preserves status, text, line, and section
- tags are extracted outside code fences
- `scan --format ndjson` emits one valid JSON object per line
- `scan --format json` groups records by type
- fixture-based outputs are stable enough for documented `jq` examples

Manual verification later can confirm that the generated output is pleasant to use from Vim, but Vim integration is not part of this slice.

## Non-Goals

This slice should not quietly grow into a full Dataview engine.

Do not add:

- SQL storage
- custom expression parsing
- inline JavaScript execution
- incremental indexing
- native `vimwiki` syntax support
- complex renderer code

## Success Criteria

This design is successful when:

- `vimwiki-query scan --root <wiki> --format ndjson` emits stable denormalized records
- `vimwiki-query scan --root <wiki> --format json` emits a grouped document derived from the same records
- the schema is simple enough that common Dataview-like queries can be expressed in `jq`
- tests freeze the parser and output behavior for the Markdown MVP
- the project remains honest about what it is: a structured parser plus queryable JSON, not a Dataview clone
