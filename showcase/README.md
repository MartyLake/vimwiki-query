# Showcase

This showcase is a small self-contained wiki that mirrors the conventions used
by the real scanner:

- diary files live under `showcase/wiki/diary/`
- project pages live under `showcase/wiki/projects/`
- skill pages live under `showcase/wiki/skill/`
- projects are identified by frontmatter convention
- diary tasks mention projects through wiki links
- query scripts honor `SHOWCASE_WIKI_ROOT` and `VIMWIKI_QUERY_BIN` overrides

Example:

```sh
bash showcase/queries/projects-with-open-todos.sh
```
