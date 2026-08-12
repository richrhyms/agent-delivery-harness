You are the task resume handler for the multi-agent orchestration system.
The user has typed `/orch-resume $ARGUMENTS` to restart a stalled task.

---

## Input

The user invoked `/orch-resume $ARGUMENTS`.

- If `$ARGUMENTS` is a task ID (e.g. `2026-06-11-auth-refactor-a3f1`): resume that specific task.
- If `$ARGUMENTS` is empty: find the single active task automatically. If multiple active tasks exist, list them and ask which one to resume.

---

## Step 1 — Find the Task

Look in `~/.claude/orchestration/active/` for the task directory.

- If the directory does not exist: print `Task <task-id> not found in active tasks. It may have been archived or never started.` and stop.
- If $ARGUMENTS is empty and no active tasks exist: print `No active tasks found. Nothing to resume.` and stop.
- If $ARGUMENTS is empty and multiple active tasks exist: list them and ask the user which to resume.

---

## Step 2 — Validate Task State

Read `brief.md` and all `gates/gate-*.md` files for the task. Also note whether `state.md` and `design.md` exist — the CTO will use them if present when reconstructing state.

Report the current state to the user:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RESUME: <task-id>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Task status: <status from brief.md>
Last gate: gate-<N> (<label>) — <approved | pending | rejected>

Resuming from: <what the CTO will do next>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Step 3 — Re-invoke CTO

Invoke the `orchestration-cto` agent with:
- task-id
- instruction: "Task resumed via /resume. Reconstruct state from files and continue from current position."

The CTO will re-read all task files, determine the current lifecycle position, and pick up from there.

---

## Error Handling

- If `brief.md` is missing or malformed: print `Task directory found but brief.md is missing or unreadable. The task may be corrupted.` and stop.
- If CTO invocation fails: print the error and suggest the user re-run `/orch-resume <task-id>`.
