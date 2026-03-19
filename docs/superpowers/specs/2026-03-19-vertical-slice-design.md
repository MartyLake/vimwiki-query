# Vimwiki Query Vertical Slice Design

Date: 2026-03-19

## Goal

Build the first useful vertical slice of `vimwiki-query` by proving the intended architecture end to end:

- a Python CLI owns indexing and status reporting
- a SQLite-backed cache persists index state per wiki root
- a thin classic Vim plugin shells out to the CLI

This slice is intentionally pre-query. Its purpose is to validate the project shape, persistence boundary, and Vim integration path before adding query parsing or rendering.

## Scope

Included in this slice:

- repository scaffold for CLI and Vim plugin code
- executable launcher at `bin/vimwiki-query`
- Python package under `python/vimwiki_query/`
- `index` command with full rebuild behavior
- `status` command for human-readable index state
- Markdown file discovery under a provided wiki root
- SQLite schema bootstrap
- persisted index metadata and page records
- thin Vim commands for `:VimwikiQueryIndex` and `:VimwikiQueryStatus`
- automated tests for CLI behavior and schema bootstrap

Explicitly out of scope:

- query parsing or evaluation
- task extraction
- quickfix or scratch-buffer query rendering
- incremental indexing
- native `vimwiki` syntax support
- background watch mode

## Recommended Approach

The first implementation slice should be `status + full index + SQLite bootstrap + Vim stub`.

Why this shape:

- it proves the CLI/Vim boundary early
- it exercises the persistent storage design from the handoff
- it provides a usable command pair without prematurely designing query UX
- it avoids throwaway architecture that would need replacement once indexing becomes real

Alternative approaches were considered and rejected:

- `status + schema only` was too shallow to prove discovery or persistence
- in-memory query work would front-load UX but work against the SQLite-first design

## Architecture

The slice has two executable surfaces and one shared data boundary.

### CLI Surface

The CLI is the primary system and lives under `python/vimwiki_query/` with a small launcher script at `bin/vimwiki-query`.

Commands for this slice:

- `vimwiki-query index --root /path/to/wiki`
- `vimwiki-query status --root /path/to/wiki`

`index` responsibilities:

- validate the root path
- discover Markdown files beneath the root
- resolve the cache directory for that root
- create or migrate the SQLite schema
- write index metadata
- insert or replace page rows

`status` responsibilities:

- resolve the cache directory for the root
- detect whether an index exists
- report root, schema version, last indexed timestamp, and indexed page count
- return a clean non-zero exit when status cannot be read

### Data Boundary

SQLite is the persistent boundary. This slice only needs enough schema to support page storage and index state.

Minimal initial tables:

- `pages`
- `index_state`

Minimal `pages` fields for this slice:

- `id`
- `root_path`
- `rel_path`
- `abs_path`
- `name`
- `stem`
- `folder`
- `title`
- `syntax`
- `frontmatter_json`
- `ctime`
- `mtime`

Minimal `index_state` fields for this slice:

- `root_path`
- `schema_version`
- `syntax`
- `indexed_at`
- `page_count`

The first slice keeps content extraction narrow. Page metadata may initially be derived from the file path and defaults, with optional frontmatter title support if that stays cheap and well-tested.

### Vim Surface

The Vim side stays deliberately thin.

Initial commands:

- `:VimwikiQueryIndex`
- `:VimwikiQueryStatus`

Responsibilities:

- determine the active wiki root from arguments or Vimwiki configuration when available
- build the CLI invocation
- shell out synchronously
- display CLI output or a short error message

The plugin should not parse wiki files, manage database state, or implement query logic. Those responsibilities belong to the CLI.

## File Layout

Initial repository shape for this slice:

```text
vimwiki-query/
  README.md
  bin/
    vimwiki-query
  plugin/
    vimwiki_query.vim
  autoload/
    vimwiki_query.vim
  python/
    vimwiki_query/
      __init__.py
      cli.py
      config.py
      discovery.py
      db.py
      indexer.py
      status.py
      model/
        __init__.py
        page.py
  tests/
    fixtures/
      wiki/
        index.md
        projects/
          roadmap.md
    test_cli.py
    test_indexer.py
  docs/
    handoff.md
```

Responsibilities by module:

- `cli.py`: argument parsing and command dispatch
- `config.py`: cache path resolution and schema version constants
- `discovery.py`: Markdown file discovery from a wiki root
- `db.py`: SQLite connection, schema bootstrap, row persistence helpers
- `indexer.py`: full rebuild orchestration
- `status.py`: human-readable status report assembly
- `model/page.py`: page data structure for persistence input

## Data Flow

### `index`

1. Parse `--root`
2. Validate the root directory exists
3. Discover Markdown files under the root
4. Convert discovered files into page records
5. Open the root-specific SQLite DB
6. Create schema if missing
7. Replace stored page rows and update `index_state`
8. Print a short success summary

### `status`

1. Parse `--root`
2. Resolve the root-specific cache directory
3. Detect whether `index.sqlite3` exists and contains readable state
4. Print a short human-readable summary

## Error Handling

Errors should stay short, text-first, and suitable for classic Vim.

CLI requirements:

- invalid or missing root path returns non-zero with a short error
- unreadable or missing index returns non-zero with a short status message
- internal exceptions should not print full tracebacks by default

Vim requirements:

- show the CLI output directly on success
- convert non-zero exits into friendly `echoerr` or equivalent
- do not dump Python tracebacks into the editor

Verbose/debug mode is deferred.

## Testing Strategy

This slice is test-first and CLI-centric.

Required tests:

- `status` reports a clean “not indexed” result before any index is built
- `index` creates the cache directory and SQLite DB for a fixture wiki
- `index` stores the correct page count for discovered Markdown files
- repeated `index` runs are idempotent at the schema/bootstrap level
- `status` reports root, schema version, last indexed timestamp, and page count after indexing

Test fixtures should use a small Markdown wiki tree with nested folders.

Manual verification for Vim:

- `:VimwikiQueryIndex` shells out correctly
- `:VimwikiQueryStatus` displays the returned text
- obvious CLI errors surface as editor messages rather than raw tracebacks

## Non-Goals

This slice should not quietly expand into query work.

Do not add:

- AST or parser code
- task or link indexing beyond what is needed for page records
- inline refresh features
- async Vim jobs
- native `vimwiki` syntax parsing

## Success Criteria

This design is successful when:

- running `vimwiki-query index --root <wiki>` creates a persistent SQLite-backed index
- running `vimwiki-query status --root <wiki>` reports meaningful state from that index
- the Vim plugin can invoke both commands from classic Vim
- tests cover the command behavior and schema bootstrap path
- the code structure clearly supports later addition of real metadata extraction and query execution
