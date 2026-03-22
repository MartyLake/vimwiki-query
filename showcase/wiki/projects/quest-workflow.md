---
type: project
status: active
goal: demonstrate the dedicated quest workflow for agents
next_step: use /quests once, then /checkpoint or /split as needed
tags:
  - demo
  - quest
---

# Quest Workflow

This project page exists only to showcase the dedicated quest flow.

## Flow

- `/quests` suggests the active quest for this session.
- The human says YES to bind it.
- `/checkpoint` drafts the next checkpoint for that quest.
- The human says YES to append it.
- `/split` drafts a new quest name and handoff when the work drifts.

## Constraint

The quest stays fixed after it is chosen. The agent does not roam and pick tasks autonomously.

## Checkpoint

## 2026-03-22

Codex: The active quest stayed fixed and the showcase work is now committed.

The session stayed inside the chosen quest and completed the showcase work already in progress. The showcase now has working quest-board, CRM, and deadlinks dashboards; the parser recognizes both wiki and Markdown links; deadlinks ignores generated navigation sections and external links; and the SnipMate pack is available for page instantiation. Next, either refine the remaining showcase docs/examples or split if a new line of work becomes the priority.

The active quest stayed fixed and the showcase work is now committed. The repo has working quest-board, CRM, and deadlinks dashboards; the parser emits wiki and Markdown links, distinguishes external links, and the deadlinks query ignores generated navigation sections and external targets. The SnipMate pack is present for page instantiation, and the full test suite passes. Next, keep refining the remaining showcase/docs if needed, or split only if a new line of work becomes distinct.
