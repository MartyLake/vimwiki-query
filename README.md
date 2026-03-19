# vimwiki-query

Companion plugin and query engine for Dataview-like queries over Vimwiki content.

Primary design decisions:

- Classic Vim first
- Markdown syntax is the MVP
- Native `vimwiki` syntax is v2
- External index/query CLI plus thin Vimscript integration
- No changes required in `vimwiki` core

Detailed handoff:

- [docs/handoff.md](/Users/mtt/.vim/bundle/vimwiki-query/docs/handoff.md)
- [docs/cookbook.md](/Users/mtt/.vim/bundle/vimwiki-query/docs/cookbook.md)

## Prototype

Current prototype scope:

- scans a Markdown-syntax Vimwiki root
- emits denormalized `page`, `task`, `heading`, and `link` records
- supports `ndjson` and grouped `json` output
- is designed to be queried with `jq`

Run the scanner on a wiki root:

```sh
bin/vimwiki-query scan --root ~/vimwiki --format ndjson
```

Emit grouped JSON instead:

```sh
bin/vimwiki-query scan --root ~/vimwiki --format json
```

Example `jq` query for open tasks:

```sh
bin/vimwiki-query scan --root ~/vimwiki --format ndjson \
  | jq -s 'map(select(.type == "task" and (.completed | not)))'
```
