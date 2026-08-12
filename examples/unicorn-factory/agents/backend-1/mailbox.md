---
task-id: 2026-06-25-unicorn-factory-mvp-c3f2
agent: backend-1
role: Backend Engineer
project: unicorn-factory
project-config: ~/.claude/orchestration/projects/unicorn-factory.md
pm-approved: true
pm-approved-at: 2026-06-25T19:00:00Z
assigned-at: 2026-06-25T19:00:00Z
gate: 7-fix
---

## Task

Apply a one-line `.gitignore` patch to resolve QA-23 (FAIL) from gate-6. The `.env*` glob currently matches `.env.example` and gitignores it, meaning `.env.example` cannot be committed. This is the only change needed.

**This is a single targeted fix. Do not touch any file other than `.gitignore`.**

## Context

- Project root: `~/projects/unicorn-factory/`
- File to patch: `~/projects/unicorn-factory/.gitignore`
- Problem: line 34 (or thereabouts) contains `.env*`, which matches `.env.example`
- Fix: add `!.env.example` on the line immediately after the `.env*` entry

## Required Change

```diff
  .env*
+ !.env.example
```

Rules:
- Do NOT remove `.env*` — it must stay to protect real secret files
- The negation `!.env.example` must appear on the very next line after `.env*`
- No other files may be modified

## Verification

After making the change, verify:
1. The `.gitignore` file contains both `.env*` and `!.env.example` (in that order)
2. `.env.example` still exists at the project root
3. No other files were modified

## Output

Write your gate file to:
  `~/.claude/orchestration/active/2026-06-25-unicorn-factory-mvp-c3f2/gates/gate-7-fix.md`

Gate file must include:
- The exact before/after diff of `.gitignore`
- Confirmation that no other files were modified
- All acceptance criteria checked [x] or [ ] with a note if [ ]
- The instruction for the user to type `/orch-approve`

## Acceptance Criteria

1. [ ] `.gitignore` contains `!.env.example` on the line immediately after `.env*`
2. [ ] `.env*` line is still present (not removed or replaced)
3. [ ] No files other than `.gitignore` were modified
4. [ ] `.env.example` is present at the project root
