---
task-id: 2026-06-25-unicorn-factory-mvp-c3f2
gate: 2
label: Spec Approval
written-by: spec-specialist
status: approved
approved-at: 2026-06-25T17:05:00Z
---

## What Was Done

Read the brief and plan in full. Source requirements file at `~/projects/unicorn-factory/docs/unicorn-factory-requirements.md` does not exist — spec was derived entirely from the brief. Produced a complete functional specification covering all 8 required sections: screen inventory (8 routes), database schema, state machine, API routes (11 routes), LLM prompt contracts, mock data definitions, environment variables, and explicit scope exclusions.

## Deliverable

`~/.claude/orchestration/active/2026-06-25-unicorn-factory-mvp-c3f2/spec.md`

## Acceptance Criteria Met

- [x] All 7 screens fully specified (8 routes including landing page at `/`)
- [x] Database schema defined — `email_leads` and `projects` tables with RLS policies; Supabase Auth integration notes
- [x] State machine defined — 8 states, all transitions with trigger events and guard conditions
- [x] All API routes listed with TypeScript request/response shapes — 11 routes total
- [x] Both LLM prompt contracts written — exact system prompt text, user prompt templates, output schemas, failure handling
- [x] Mock data payloads complete — all 11 mock payloads using "a tool for freelancers to track invoices" as seed example
- [x] Environment variables enumerated — 5 variables with purposes, example values, and security notes
- [x] Scope boundary list present — 15 explicit out-of-scope exclusions with reasons

## Issues / Gaps Found

1. **Source requirements file missing** — `~/projects/unicorn-factory/docs/unicorn-factory-requirements.md` does not exist. Spec was derived entirely from the brief. If the requirements file is created before G-3, the Architect should read it to check for any additions not captured here.

2. **Model ID assumption** — The brief specifies "Claude Haiku via Vercel AI SDK". Spec uses `claude-haiku-4-5` as the model ID string with `ANTHROPIC_MODEL` env var override. Backend-1 agent must verify the exact model ID string accepted by `@ai-sdk/anthropic` at implementation time. Added as Open Question 3.

3. **Research/Build route trigger pattern** — The brief specifies agent runs as sequential. Spec implements a `phase: "start" | "complete"` pattern on the research/build routes so the progress screen UI can control animation timing while keeping state transitions server-authoritative. This is an implementation-level clarification, not a spec change.

---
Type `/orch-approve` to confirm spec and proceed to G-3 (Architect), or `/orch-approve reject <feedback>` to revise.
