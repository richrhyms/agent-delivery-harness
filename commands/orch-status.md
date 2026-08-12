You are the status reporter for the multi-agent orchestration system.
The user has typed `/orch-status $ARGUMENTS` to check the state of active or archived tasks.

---

## Input

The user invoked `/orch-status $ARGUMENTS`.

- If `$ARGUMENTS` is a task ID: show detailed status for that specific task.
- If `$ARGUMENTS` is empty: show a summary of all active tasks.
- If `$ARGUMENTS` is `all`: show active tasks + recent archived tasks (last 5).

---

## Step 1 — Gather Task State

### For a specific task ID:

1. Look in `~/.claude/orchestration/active/<task-id>/` first.
2. If not found, look in `~/.claude/orchestration/archive/<task-id>/`.
3. If not found in either: print `Task <task-id> not found.` and stop.
4. Read `brief.md`, `plan.md` (if it exists), and all `gates/gate-*.md` files.

### For all active tasks:

Glob `~/.claude/orchestration/active/*/brief.md` and read each one.

---

## Step 2 — Format and Print

### Single task (detailed):

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TASK: <task-id>
Status: <status from brief.md>
Created: <created date>
Source: <input type + source>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Goal: <goal from brief.md>

Gate History:
  gate-0  [approved]  Understanding Confirmation
  gate-1  [approved]  Plan Approval
  gate-2  [pending]   Spec Approval          ← current
  gate-3  [—]         (not started)

Pending action: <what needs to happen next>
  → Type /orch-approve to advance, or /orch-resume <task-id> to re-trigger the CTO.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### All active tasks (summary):

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ACTIVE TASKS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  <task-id>  [<status>]  <goal — first sentence>
             Last gate: gate-<N> (<label>) — <gate status>

  <task-id>  [<status>]  <goal>
             Last gate: gate-<N> (<label>) — <gate status>

No active tasks.   ← if empty
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Step 3 — Suggest Next Action

At the end of the output, suggest the most relevant next command:

- If a gate is `pending`: `Type /orch-approve to advance task <task-id>.`
- If a task is stalled (no pending gate and not complete): `Type /orch-resume <task-id> to re-trigger the CTO.`
- If no active tasks: `Type /orch <input> to start a new task.`

---

## Error Handling

- If active directory does not exist or is empty: print `No active tasks found.`
- If a brief.md is unreadable: note it in the output as `[unreadable — may be corrupted]` and continue with other tasks.
