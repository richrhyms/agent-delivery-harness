---
task-id: 2026-06-25-unicorn-factory-mvp-c3f2
gate: 7-fix
label: Backend Fix — .gitignore patch (QA-23)
written-by: backend-1
status: approved
approved-at: 2026-06-26T09:00:00Z
---

## What Was Done

Applied a single-line negation rule to `.gitignore` to resolve QA-23. The `.env*` pattern was swallowing `.env.example`, preventing it from being committed. Added `!.env.example` immediately after the `.env*` line.

## Deliverable

File patched: `~/projects/unicorn-factory/.gitignore`

No PR raised — this is a local file patch (no git branch/remote configured yet; DevOps in G-7 handles repo creation and push).

## Diff

```diff
 # env files (can opt-in for committing if needed)
 .env*
+!.env.example
```

Before (line 34): `.env*` (no negation — `.env.example` was gitignored)
After (lines 34-35): `.env*` followed by `!.env.example`

## Acceptance Criteria Met

- [x] `.gitignore` contains `!.env.example` on the line immediately after `.env*`
- [x] `.env*` line is still present (not removed or replaced)
- [x] No files other than `.gitignore` were modified
- [x] `.env.example` is present at the project root (`~/projects/unicorn-factory/.env.example` confirmed)

## Next Phase (if approved)

CTO will invoke QA Engineer for re-run. If QA returns PASS, advance to G-7 DevOps (GitHub repo creation + Vercel deployment).

---
Type `/orch-approve` to confirm and advance to QA re-run, or `/orch-approve reject <feedback>` to request revisions.
