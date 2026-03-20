# LLM Quest Wrapper Design

## Purpose

Design a thin LLM-facing skill wrapper around the existing `vimwiki-query` plugin and Quest Board model.

The wrapper should let an LLM help with context recovery and proposal drafting without becoming a second query engine or gaining autonomous write access to durable wiki state.

## Problem

The current `vimwiki-query` project already provides the core query and rendering capabilities for Vimwiki content. What is missing is a constrained interface that an LLM can safely use.

Without such a wrapper, the model either:

- talks to raw plugin internals, which is too much surface area
- or guesses at user intent without a reliable command vocabulary

The wrapper should solve the interaction problem, not the indexing problem.

## Design Goal

Expose a single generic `quest` skill entry point that can:

- read the Quest Board
- inspect one project page
- summarize context for a human handoff
- draft proposed checkpoint updates
- draft proposed project splits

The wrapper should be easy for an LLM to remember, easy for a human to audit, and limited enough that it cannot mutate durable wiki state without approval.

## Non-Goals

- Reimplementing the query engine
- Replacing the `vimwiki-query` plugin
- Full autonomous wiki editing by the LLM
- A new storage layer or project-state database
- A general-purpose agent orchestration system

## Recommended Boundary

The wrapper should be a skill layer on top of the existing plugin.

That means:

- `vimwiki-query` remains the backend query and render system
- the skill translates intent into a small set of allowed operations
- the skill can propose writes, but not commit them autonomously

This is the right boundary because it preserves the current plugin investment while adding a safe LLM interaction surface.

## Command Shape

The skill should expose one generic top-level command: `quest`.

Recommended subcommands:

- `quest board`
- `quest open <page>`
- `quest summarize <page>`
- `quest draft-update <page>`
- `quest draft-split <page>`

The command should act like a constrained router:

- read operations return query results or concise summaries
- propose operations return draft text the user can review
- write operations remain out of scope for the initial skill

## Permission Model

The wrapper should be explicitly `read + propose`.

Allowed:

- query Quest Board state
- inspect a single project page
- summarize a page or checkpoint trail
- draft a checkpoint update
- draft a split proposal

Not allowed:

- edit wiki files directly
- create new projects autonomously
- rewrite frontmatter
- append checkpoint history
- rename pages

If later expanded, write access should be a separate, deliberate capability.

## How the LLM Uses It

The wrapper should serve three common LLM tasks:

### Context Recovery

The model should be able to ask for the Quest Board or a single page, then reconstruct where work stands.

### Handoff Summaries

The model should be able to produce a concise summary for the human that answers:

- what changed
- what is true now
- what remains unresolved

### Drafting Proposals

The model should be able to draft:

- checkpoint updates
- project split proposals

These drafts should be written in a form that is ready for human approval or copy into the wiki.

## Why Generic `quest` Is the Right Shape

One generic command with subcommands is easier for an LLM to use than a wide set of unrelated operations.

Benefits:

- one mental model
- easier prompt/tool documentation
- easier permission reasoning
- simpler future extension

It also mirrors the conceptual model already established by the Quest Board and project-page workflow.

## Interaction Flow

1. The LLM receives a task that touches wiki state.
2. It invokes `quest` with the relevant subcommand.
3. The wrapper queries the existing `vimwiki-query` backend.
4. The wrapper returns either:
   - a board view
   - a page view
   - a summary
   - a draft proposal
5. The human reviews any proposed writes before durable state changes happen.

## Data Sources

The wrapper should rely on the same data that powers the Quest Board:

- markdown project pages
- frontmatter
- checkpoint history
- rendered board/query output from `vimwiki-query`

It should not invent a separate canonical model.

## Output Expectations

The wrapper should produce outputs that are concise enough for an LLM to consume and specific enough for a human to audit.

Recommended output forms:

- structured text summary
- quoted draft checkpoint proposal
- quoted draft split proposal
- link or path to source page

Avoid returning huge raw transcripts unless explicitly requested.

## Safety Principles

- Durable state should be updated only by explicit human approval.
- The wrapper should prefer drafts over direct edits.
- The command surface should remain small enough to be documented in one screen.
- If the LLM is uncertain, it should ask for the board or page rather than infer hidden state.

## Future Expansion

Possible later additions:

- a separate write-capable skill
- tool or MCP wrapper for programmatic integration
- automatic insertion of approved drafts into wiki files
- richer page diffs or structured checkpoint formatting

These are follow-on capabilities, not prerequisites for the first wrapper.

## Success Criteria

The wrapper is successful if an LLM can:

- recover context from the Quest Board quickly
- inspect a project page without knowing plugin internals
- draft a useful checkpoint update
- draft a useful split proposal
- avoid touching durable wiki state without human approval
