# Quest Board Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a first-slice quest-board showcase that renders project re-entry cards from explicit task state and frontmatter-only project metadata.

**Architecture:** Keep the scanner unchanged. Implement the board as one new showcase shell script that consumes existing `scan --format ndjson` output, classifies project pages in `jq`, and prints markdown cards with empty sections always rendered. Add one showcase test to lock down section coverage and one cookbook example to document the query pattern.

**Tech Stack:** Bash, `jq`, existing Python scanner/CLI, `pytest`

---

## Chunk 1: Add Quest Board Showcase Script

**Files:**
- Create: `showcase/queries/quest-board.sh`

- [ ] **Step 1: Write the failing test**

Add a new showcase assertion in `tests/test_showcase.py` that runs `quest-board.sh` and checks for:
- `# Quest Board`
- all six section headers
- at least one card in `Needs Decision`, `Blocked`, or `Waiting`
- one empty-section reassurance line such as `No active projects.`

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/test_showcase.py -k quest_board -v`
Expected: FAIL because `showcase/queries/quest-board.sh` does not exist yet.

- [ ] **Step 3: Write minimal implementation**

Create `showcase/queries/quest-board.sh` using the existing showcase pattern:

```bash
#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/wiki"

bin/vimwiki-query scan --root "$ROOT" --format ndjson \
  | jq -r -s '...'
```

The `jq` program should:
- collect project pages with `frontmatter.type == "project"`
- normalize project identity from scanner-resolved page targets
- classify projects by precedence:
  - `Recently Finished`
  - `Needs Decision`
  - `Blocked`
  - `Waiting`
  - `Stale`
  - `Active`
- render each section even when empty
- render one compact markdown card per project
- use explicit project-page tasks plus explicit diary-task links

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/test_showcase.py -k quest_board -v`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add showcase/queries/quest-board.sh tests/test_showcase.py
git commit -m "feat: add quest board showcase"
```

## Chunk 2: Add Cookbook Example

**Files:**
- Modify: `docs/cookbook.md`

- [ ] **Step 1: Write the failing test**

Add a small cookbook-oriented test in `tests/test_showcase.py` or extend the quest-board showcase test to assert the query script is documented in `docs/cookbook.md` with a `quest-board` example reference.

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/test_showcase.py -k quest_board -v`
Expected: FAIL until the cookbook section exists.

- [ ] **Step 3: Write minimal implementation**

Add a short `## Quest Board` section to `docs/cookbook.md` that shows how to run:

```sh
bash showcase/queries/quest-board.sh
```

Keep the example brief. Do not duplicate the full query body.

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/test_showcase.py -k quest_board -v`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add docs/cookbook.md
git commit -m "docs: add quest board cookbook example"
```

## Chunk 3: Verify Showcase Contract

**Files:**
- Modify: `tests/test_showcase.py`

- [ ] **Step 1: Write the failing test**

Add a second test that checks the board output shape more specifically:
- all six sections render in order
- empty sections include reassurance text
- cards include `Goal:`, `Reason:`, `Counts:`, and `Updated:`
- `Updated:` is rendered as `YYYY-MM-DD`

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/test_showcase.py -k quest_board -v`
Expected: FAIL until the output shape is exact.

- [ ] **Step 3: Write minimal implementation**

Adjust the `jq` rendering in `showcase/queries/quest-board.sh` to satisfy the exact markdown contract without changing the scanner.

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/test_showcase.py -k quest_board -v`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add showcase/queries/quest-board.sh tests/test_showcase.py
git commit -m "test: lock down quest board output shape"
```

## Chunk 4: Final Verification

**Files:**
- None

- [ ] **Step 1: Run the full showcase test file**

Run: `pytest tests/test_showcase.py -v`
Expected: PASS.

- [ ] **Step 2: Run the new showcase script manually**

Run: `bash showcase/queries/quest-board.sh`
Expected: Markdown board with six sections and deterministic cards.

- [ ] **Step 3: Review git status**

Run: `git status --short`
Expected: Only the intended plan-following implementation changes remain.

- [ ] **Step 4: Commit if anything remains uncommitted**

If needed, commit the remaining implementation and docs changes with a single focused message.
