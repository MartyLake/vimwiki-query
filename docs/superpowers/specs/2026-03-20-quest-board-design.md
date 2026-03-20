# Quest Board Design

Date: 2026-03-20

## Goal

Add a first-slice "Quest Board" showcase to `vimwiki-query` that turns project
pages plus explicitly linked task state into one generated re-entry board.

The board should answer, quickly:

- what needs a decision
- what is blocked
- what is waiting
- what has gone stale
- what is still active
- what was recently finished

This is a read-only derived view. It is not a workflow engine.

## Scope

The first slice should be a showcase query that emits markdown directly.

It should:

- discover candidate project pages from existing scanner output
- classify each project into exactly one board section
- use frontmatter plus explicit task tags only
- infer project state from both project-page tasks and explicitly linked diary
  tasks
- render one compact markdown card per project

It should not:

- parse checkpoint summaries from page bodies
- infer state from plain-text mentions
- mutate project pages
- add dependency graphs or tree rendering
- build a general plugin rendering engine first

## Boundaries

The first slice should keep responsibilities narrow:

- scanner: provide raw page, task, and link records exactly as it already does
- query: discover candidate projects, normalize project identity, derive
  counts, classify sections, and choose reason lines
- renderer: format the already-classified result as markdown

The quest board should be a query-and-render feature, not a scanner redesign.

## Discovery Rules

Candidate projects are:

- pages where `frontmatter.type == "project"`

No extra folder convention or tag should be required in the first slice.

## Data Sources

The first slice uses:

- page frontmatter
- page `mtime`
- open tasks on the project page
- open tasks in diary notes that explicitly link to the project page

For the first slice, project pages are expected to provide these card fields in
frontmatter:

- `goal`
- `next_step`

The first slice does not use:

- plain-text mentions
- page-body checkpoint extraction
- page-level frontmatter state for blocked / waiting / needs-decision

Those board states must come from explicit open task tags only.

## State Tags

The first slice should recognize these open-task tags:

- `#needs-decision`
- `#blocked`
- `#wait`
- `#waiting`
- `#waitingfor`

These tags may appear:

- on tasks on the project page
- on diary tasks that explicitly link to the project

If one task links to multiple projects, it contributes to all explicitly linked
projects.

Nested tasks count the same as top-level tasks.

## Project State Inheritance

A project should inherit operational state from two sources:

1. open tasks on the project page itself
2. open diary tasks that explicitly link to that exact project page

Explicit wiki links are required. No plain-text inference or project-tag
heuristics should be used.

Links to a project section such as `[[/projects/example#Next]]` still count as
links to that project for inheritance, counts, and classification.

Project identity should be normalized at the page level using the scanner's
resolved page target. In practice, section fragments collapse to the canonical
project page identity after scanner resolution.

The canonical project key for classification, dedupe, counting, and card
grouping should therefore be the scanner-resolved page target, not raw link
text.

Counts and state classification should use the same source set so the board
does not show contradictory signals.

For diary tasks, project inheritance should use a line-based join: every
explicit project link resolved on the same task line contributes that task to
the linked project's source set.

## Section Model

The board should have these sections, in this order:

1. `Needs Decision`
2. `Blocked`
3. `Waiting`
4. `Stale`
5. `Active`
6. `Recently Finished`

Each project should appear in exactly one section.

## Classification Rules

Classification should use a precedence ladder so section membership is
exclusive.

### 1. Recently Finished

A project belongs in `Recently Finished` when:

- `frontmatter.status == "archived"`
- and the project page `mtime` is within `RECENT_FINISHED_DAYS=7`

Archived projects older than that window should not appear on the board.

`archived` wins over all task-derived states. Even if an archived project still
has open `#blocked`, `#waiting`, or `#needs-decision` tasks, it remains in the
archived path and does not surface in other sections.

### 2. Needs Decision

A non-archived project belongs in `Needs Decision` when it has at least one
open task tagged `#needs-decision`.

This state is derived only from explicit task tags, not frontmatter status.

### 3. Blocked

A non-archived project belongs in `Blocked` when it has at least one open task
tagged `#blocked`, unless it already qualified for `Needs Decision`.

`Blocked` wins over `Waiting`.

### 4. Waiting

A non-archived project belongs in `Waiting` when it has at least one open task
tagged with any waiting signal:

- `#wait`
- `#waiting`
- `#waitingfor`

and it does not already qualify for `Needs Decision` or `Blocked`.

### 5. Stale

A non-archived project belongs in `Stale` when:

- it does not already qualify for `Needs Decision`, `Blocked`, or `Waiting`
- and its project-page `mtime` is older than `STALE_DAYS=7`

Staleness is based on the project page `mtime` only. Recent diary mentions do
not make a project fresh.

### 6. Active

A non-archived project belongs in `Active` when:

- it does not fall into any higher-priority section
- and it has at least one actionable signal

For the first slice, actionable signal means either:

- at least one open task from the project-source set
- or a non-empty `next_step`

If a non-archived project has no open tasks and no `next_step`, it should be
omitted from the board.

`Active` is therefore not a catch-all for every non-archived project. It is the
fallback only for non-archived projects that still expose actionable work.

## Card Shape

Cards should be compact markdown cards rather than one-line bullets.

Each card should include:

- project page link
- `goal` if present
- a reason line
- small task counts
- last updated date

Cards should degrade gracefully if `goal` or `next_step` is missing.

The first slice should not require every project to be perfectly maintained in
order to appear.

## Reason Line Rules

The reason line depends on section:

- `Needs Decision`: first matching `#needs-decision` task
- `Blocked`: first matching `#blocked` task
- `Waiting`: first matching waiting-tag task
- `Active`: `next_step`, or if missing, the first open task from the
  project-source set
- `Stale`: `next_step` if present, otherwise a stale note without inventing a
  synthetic task reason
- `Recently Finished`: no task reason required

When a matching reason task could come from multiple sources, choose:

1. project-page task first
2. diary task second

Within the same source type, choose deterministically by:

1. file path
2. line number

If the reason line comes from a diary task, it should include the diary-note
link as the source while keeping the project page as the main card link.

For project identity, inheritance, counts, and the main card link, links such
as `[[/projects/example#Next]]` should be normalized to the canonical project
page `[[/projects/example]]`. The reason-line task text may preserve the
original section link as written.

## Counts

Cards should include small counts so the board remains operational rather than
purely narrative.

The first slice should include:

- open task count
- needs-decision task count
- blocked task count
- waiting task count

These counts should include both:

- open tasks on the project page
- open diary tasks that explicitly link to the project

Admin or follow-up diary tasks still count if they explicitly link to the
project. The board is meant to reflect real operational load, not only tasks
written on the canonical project page.

The counting unit is one task record per project. A single task should count at
most once for a given project, even if it mentions that same project multiple
times or links to one of its sections more than once.

If one open task has multiple state tags, state counting should follow the same
precedence ladder as section classification:

1. `#needs-decision`
2. `#blocked`
3. waiting tags (`#wait`, `#waiting`, `#waitingfor`)

That means one task contributes to only one state bucket:

- `#needs-decision` tasks do not also increment blocked or waiting counts
- `#blocked` tasks do not also increment waiting counts
- waiting-tag variants collapse into one waiting bucket

## Sorting

Projects should be sorted deterministically within each section.

The first slice should use:

1. oldest project-page `mtime` first
2. path alphabetical

This keeps the board boring and predictable.

`Updated:` should render as `YYYY-MM-DD`.

## Output Shape

The board should be emitted as one markdown document with section headings.

All sections should always render, even when empty. Empty sections should show
a short reassurance line such as:

- `No projects need a decision.`
- `No blocked projects.`
- `No waiting projects.`
- `No stale projects.`
- `No active projects.`
- `No recently finished projects.`

Recommended shape:

```md
# Quest Board

## Needs Decision

### [[/projects/example-project]]
- Goal: Decide launch shape for the first slice
- Reason: choose between foo or bar before ordering
- Counts: open 4, needs-decision 1, blocked 0, waiting 0
- Updated: 2026-03-20

## Blocked

### [[/projects/another-project]]
- Goal: Ship the blog pipeline
- Reason: waiting on API access from vendor
- Counts: open 6, needs-decision 0, blocked 1, waiting 2
- Updated: 2026-03-18
```

Exact markdown wording may change during implementation, but the board should
stay card-oriented rather than collapse into one-line bullets.

The first slice does not need a summary header with section counts.

## Relationship To Existing Queries

This is not just a rename of existing project queries.

Existing queries already cover fragments of the model:

- active projects
- projects with open todos
- open tasks from project pages
- diary mentions of one project

The quest board needs a new combined query because it adds:

- exclusive section classification
- task-tag-driven project state
- cross-source project state inheritance
- compact card rendering for re-entry

## Implementation Notes

The first slice should be implemented as:

- one standalone showcase script under `showcase/queries/`

It should not begin as a generic engine or editor integration feature. A
showcase query is the right first proving ground.

## Deferred Work

The first slice deliberately defers:

- body-derived checkpoint snippets
- `parent_project` nesting
- graph or tree views
- editable boards
- dependency modeling
- plugin-specific live rendering

These can be revisited later if the compact board proves useful.

## Success Criteria

The quest board is successful if a user can open one generated view and answer,
within a few seconds:

- what needs a decision now
- what is blocked
- what is waiting
- what has gone stale
- what can be resumed immediately
- what was recently finished
