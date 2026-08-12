---
task-id: 2026-06-25-unicorn-factory-mvp-c3f2
gate: 3
label: Design Approval
written-by: architect
status: approved
approved-at: 2026-06-25T17:15:00Z
---

## What Was Done

Read the full spec and brief. Project directory `~/projects/unicorn-factory/` is greenfield (no existing code). Produced `architecture.md` covering 10 sections: project directory tree, Supabase DDL, TypeScript type contracts, state machine definition, component tree, API route map, Supabase client setup (3 variants), AI client setup, middleware auth guard, and mock data module specification. Scope is cleanly split between backend-1 (API layer, infrastructure) and frontend-1 (screens, UI components) with no overlap.

## Deliverable

`~/.claude/orchestration/active/2026-06-25-unicorn-factory-mvp-c3f2/architecture.md`

## Acceptance Criteria Met

- [x] Directory structure covers all 8 routes and all 11 API route files — complete file tree provided
- [x] Supabase DDL is complete and runnable — both tables, RLS policy, 2 indexes, updated_at trigger
- [x] TypeScript types cover all entities and all API shapes — no `any` — 30+ interfaces in types/index.ts
- [x] State machine table includes all 8 states and all 8 transitions with guards — plus TypeScript constant + assertProjectStatus helper
- [x] Component tree lists all components with their props interface names — full hierarchy with interface definitions
- [x] API route map specifies auth method, DB client, and state guard for each of the 11 routes — table provided
- [x] Supabase client initialisation covers all 3 client variants — client.ts, server.ts, service.ts with code
- [x] AI client setup includes model env var pattern and error handling approach — callLLM wrapper with retry
- [x] Middleware auth guard covers all 6 protected routes — middleware.ts with config matcher
- [x] Mock data module structure specified with all exports named — lib/mock-data.ts fully specified with all 11 mock constants

## Issues / Gaps Found

1. **MarkdownRenderer dependency** — Rendering Markdown requires `react-markdown` or a fallback `<pre>` approach. Frontend-1 must decide. Recommendation: `react-markdown`. Flagged in Open Technical Questions.

2. **State routing on sign-in** — The spec's 11 API routes do not include a "get current project" endpoint. The auth page will need to either query Supabase client-side or a 12th route (`GET /api/projects/current`) may be needed. Backend-1 is flagged to evaluate this at implementation time and add the route if required.

3. **Supabase SSR session refresh** — The server-side client's `setAll` no-op means tokens are not refreshed from API routes. Acceptable for MVP; flagged so Backend-1 is aware.

---
Type `/orch-approve` to confirm architecture and proceed to G-4 (Backend-1), or `/orch-approve reject <feedback>` to revise.
