---
name: quest
description: Use when an agent is operating under the showcase-backed wiki quest workflow and the user asks to choose a quest, draft a checkpoint, or propose a split. The skill uses the existing showcase query and sample pages, and supports `/quests`, `/checkpoint`, and `/split` with human approval before any durable wiki change.
---

# Quest

## Workflow

Use this skill for the dedicated quest flow:

- `showcase/queries/quest-board.sh` to inspect open quests in the showcase
- `showcase/wiki/projects/quest-workflow.md` as the sample active quest page
- `showcase/wiki/skill/quest.md` as the sample skill-oriented quest page
- `/quests` to suggest the active quest for this session
- `/checkpoint` to draft a checkpoint for the active quest
- `/split` to draft a split proposal when the quest has drifted or grown too large

## Rules

- One quest is explicitly chosen by the human and stays fixed for the session.
- Do not roam the wiki and pick tasks autonomously.
- Treat the quest page as the source of truth.
- Drafts are allowed; durable wiki edits require explicit approval.

## `/quests`

Use `/quests` when the session does not yet have an active quest.

Process:

1. Run or read `bash showcase/queries/quest-board.sh`.
2. Inspect the open quests shown there, with the showcase project pages as the source of truth.
3. Suggest the best match for the current session.
4. State briefly why it matches.
5. Wait for the human to say YES.

If the fit is unclear, say so and ask for clarification instead of guessing.

## `/checkpoint`

Use `/checkpoint` when there is an active quest.

Process:

1. Read the active quest page and current checkpoint context.
2. Draft the next checkpoint text.
3. Keep it consequence-oriented: what changed, what is true now, what happens next.
4. If the work has drifted or split is more appropriate, propose a split instead of forcing a normal checkpoint.
5. Wait for YES before any durable write.

## `/split`

Use `/split` when the active quest has become too large, changed shape, or needs a new task name.

Process:

1. Describe the drift or new subquest.
2. Suggest a new quest name.
3. Draft the handoff summary and split proposal.
4. Wait for YES before any durable write or page creation.

## Output Shape

Keep outputs short and easy to approve:

- `Recommended quest: ...`
- `Why: ...`
- `Draft checkpoint: ...`
- `Draft split: ...`
- `Approve?`

Do not produce long transcripts unless the user asks for them.
