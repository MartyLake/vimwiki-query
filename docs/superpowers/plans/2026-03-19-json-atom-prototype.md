# JSON Atom Prototype Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Python CLI prototype that scans a Markdown-syntax Vimwiki root and emits denormalized `ndjson` and grouped `json` records for pages, tasks, headings, and links.

**Architecture:** The prototype is a stateless scanner. A small Python package owns discovery, parsing, record shaping, and CLI output. Tests drive each behavior from the outside in, with fixture wiki files freezing the initial Markdown MVP semantics.

**Tech Stack:** Python 3 standard library, `pytest`, shell launcher in `bin/`

---

## Chunk 1: CLI Skeleton And Fixtures

### Task 1: Create the repository skeleton

**Files:**
- Create: `bin/vimwiki-query`
- Create: `python/vimwiki_query/__init__.py`
- Create: `python/vimwiki_query/cli.py`
- Create: `tests/conftest.py`
- Create: `tests/fixtures/wiki/index.md`
- Create: `tests/fixtures/wiki/projects/roadmap.md`
- Create: `tests/test_cli.py`

- [x] **Step 1: Write the failing CLI test**

```python
def test_scan_ndjson_emits_page_and_task_records(run_cli):
    result = run_cli("scan", "--root", "tests/fixtures/wiki", "--format", "ndjson")
    assert result.returncode == 0
```

- [x] **Step 2: Run test to verify it fails**

Run: `python3 -m pytest tests/test_cli.py -q`
Expected: FAIL because the CLI package/launcher does not exist yet

- [x] **Step 3: Write the minimal CLI skeleton**

Implement:
- shell launcher in `bin/vimwiki-query`
- importable package
- `scan` subcommand wiring in `cli.py`
- fixture wiki files with one page and one task-bearing project note

- [x] **Step 4: Run test to verify the failure changed appropriately**

Run: `python3 -m pytest tests/test_cli.py -q`
Expected: FAIL because `scan` does not yet emit valid records

### Task 2: Add a test helper for CLI execution

**Files:**
- Modify: `tests/conftest.py`
- Modify: `tests/test_cli.py`

- [x] **Step 1: Write the failing helper-backed test**

Add assertions for stdout parsing and stable invocation through `python3`.

- [x] **Step 2: Run test to verify it fails**

Run: `python3 -m pytest tests/test_cli.py -q`
Expected: FAIL because the helper or launcher behavior is incomplete

- [x] **Step 3: Write the minimal helper**

Implement:
- fixture that runs `python3 -m vimwiki_query.cli`
- stable fixture-root resolution

- [x] **Step 4: Run test to verify it passes**

Run: `python3 -m pytest tests/test_cli.py -q`
Expected: PASS for the helper-scaffolding test

## Chunk 2: Discovery And Page Records

### Task 3: Drive Markdown file discovery

**Files:**
- Create: `python/vimwiki_query/discovery.py`
- Create: `tests/test_discovery.py`

- [x] **Step 1: Write the failing discovery test**

```python
def test_discover_markdown_files_returns_relative_paths(sample_wiki_root):
    paths = discover_markdown_files(sample_wiki_root)
    assert paths == ["index.md", "projects/roadmap.md"]
```

- [x] **Step 2: Run test to verify it fails**

Run: `python3 -m pytest tests/test_discovery.py -q`
Expected: FAIL because discovery is unimplemented

- [x] **Step 3: Write the minimal discovery implementation**

Implement:
- root validation
- recursive `.md` discovery
- deterministic sorted relative paths

- [x] **Step 4: Run test to verify it passes**

Run: `python3 -m pytest tests/test_discovery.py -q`
Expected: PASS

### Task 4: Emit page records with title and file context

**Files:**
- Create: `python/vimwiki_query/parser.py`
- Create: `python/vimwiki_query/records.py`
- Modify: `tests/test_cli.py`
- Create: `tests/test_parser.py`

- [x] **Step 1: Write the failing parser test for page records**

Test:
- frontmatter title wins
- first heading is fallback
- file metadata is denormalized into the record

- [x] **Step 2: Run test to verify it fails**

Run: `python3 -m pytest tests/test_parser.py -q`
Expected: FAIL because parsing/page shaping is unimplemented

- [x] **Step 3: Write the minimal page parsing implementation**

Implement:
- frontmatter-at-top detection
- first heading extraction
- title precedence
- page record shaping with `file` object duplication

- [x] **Step 4: Run test to verify it passes**

Run: `python3 -m pytest tests/test_parser.py -q`
Expected: PASS for page-record behavior

## Chunk 3: Tasks, Tags, Links, And Output Modes

### Task 5: Extract task and tag records through the parser

**Files:**
- Modify: `python/vimwiki_query/parser.py`
- Modify: `tests/test_parser.py`
- Modify: `tests/test_cli.py`

- [x] **Step 1: Write the failing task extraction test**

Test:
- `- [ ]` maps to `open`
- completed marker maps to `done`
- inline tags outside fenced code blocks are captured
- task record repeats page-level file context

- [x] **Step 2: Run test to verify it fails**

Run: `python3 -m pytest tests/test_parser.py -q`
Expected: FAIL because task extraction is incomplete

- [x] **Step 3: Write the minimal task extraction implementation**

Implement:
- task regexes for `[ ]`, `[x]`, `[X]`, `[.]`
- `completed` boolean
- section tracking from nearest heading
- inline tag extraction outside fenced code blocks

- [x] **Step 4: Run test to verify it passes**

Run: `python3 -m pytest tests/test_parser.py -q`
Expected: PASS

### Task 6: Extract headings and simple wiki links

**Files:**
- Modify: `python/vimwiki_query/parser.py`
- Modify: `tests/test_parser.py`

- [x] **Step 1: Write the failing heading/link test**

Test:
- Markdown headings emit `heading` records with level and text
- `[[Page]]` style links emit `link` records with normalized target text

- [x] **Step 2: Run test to verify it fails**

Run: `python3 -m pytest tests/test_parser.py -q`
Expected: FAIL because heading/link record emission is incomplete

- [x] **Step 3: Write the minimal heading/link implementation**

Implement:
- heading record emission
- simple `[[...]]` link extraction
- repeated file context on each record

- [x] **Step 4: Run test to verify it passes**

Run: `python3 -m pytest tests/test_parser.py -q`
Expected: PASS

### Task 7: Support `ndjson` and grouped `json` output from `scan`

**Files:**
- Modify: `python/vimwiki_query/cli.py`
- Modify: `tests/test_cli.py`

- [x] **Step 1: Write the failing output-mode tests**

Test:
- `--format ndjson` outputs one JSON object per line
- `--format json` outputs grouped arrays by record type
- invalid `--format` is rejected by the CLI

- [x] **Step 2: Run test to verify it fails**

Run: `python3 -m pytest tests/test_cli.py -q`
Expected: FAIL because output formatting is incomplete

- [x] **Step 3: Write the minimal output-mode implementation**

Implement:
- `scan` command orchestration
- `ndjson` writer
- grouped `json` writer for `pages`, `tasks`, `headings`, and `links`

- [x] **Step 4: Run test to verify it passes**

Run: `python3 -m pytest tests/test_cli.py -q`
Expected: PASS

## Chunk 4: Prototype Finish And Verification

### Task 8: Document prototype usage in the README

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Write the failing documentation expectation**

Record the required README sections:
- what the prototype is
- example `scan` invocations
- example `jq` pipelines

- [x] **Step 2: Verify the docs gap manually**

Run: `sed -n '1,220p' README.md`
Expected: Missing prototype usage details

- [x] **Step 3: Write the minimal README update**

Add:
- prototype framing
- `scan` examples
- one `jq` example for open tasks

- [x] **Step 4: Verify the README content**

Run: `sed -n '1,260p' README.md`
Expected: Contains the prototype usage section and examples

### Task 9: Run full prototype verification

**Files:**
- Modify: `docs/superpowers/plans/2026-03-19-json-atom-prototype.md`

- [x] **Step 1: Run the full test suite**

Run: `python3 -m pytest -q`
Expected: PASS with all tests green

- [x] **Step 2: Run the CLI prototype manually on fixtures**

Run: `python3 -m vimwiki_query.cli scan --root tests/fixtures/wiki --format ndjson`
Expected: Emits page/task/heading/link records as newline-delimited JSON

- [x] **Step 3: Run grouped JSON mode manually**

Run: `python3 -m vimwiki_query.cli scan --root tests/fixtures/wiki --format json`
Expected: Emits a grouped JSON object with `pages`, `tasks`, `headings`, and `links`

- [x] **Step 4: Mark the plan as executed**

Update this plan file by checking completed boxes that were actually completed during implementation.
