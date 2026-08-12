---
task-id: 2026-06-25-unicorn-factory-mvp-c3f2
project: unicorn-factory
written-by: cto
status: pm-approved
pm-approved-at: 2026-06-25T17:00:00Z
---

## Summary

Build the Unicorn Factory MVP: a 7-screen Next.js + Supabase web application with real auth, two real LLM calls (idea constraint check + clarifying questions), a project state machine, mock research/build pipeline screens, and a deliverables display. All mock sections labelled `// MOCK:`. Deployed to Vercel.

## Agents Involved

- Spec Specialist
- Architect
- Backend Engineer (backend-1)
- Frontend Engineer (frontend-1)
- QA Engineer
- DevOps Engineer

## Gate Sequence

| Gate | Agent(s)     | Deliverable                                    | Acceptance Criteria                                                                                  |
|------|--------------|------------------------------------------------|------------------------------------------------------------------------------------------------------|
| G-2  | Spec         | `spec.md`                                      | All 7 screens specified; DB schema defined; API routes listed; LLM prompt contracts written; env vars enumerated; mock data shape defined; `// MOCK:` points identified |
| G-3  | Architect    | `architecture.md`                              | Project directory structure; Supabase schema DDL; state machine definition; component tree; API route map; TypeScript type contracts |
| G-4  | Backend-1    | PR: scaffolded Next.js project + all API routes | Project init complete; Supabase client configured; state machine implemented; two LLM API routes working (constraint check + clarifying Qs); mock data service complete; all `// MOCK:` labels in place; `.env.example` present; no `any` types |
| G-5  | Frontend-1   | PR: all 7 UI screens implemented               | Landing page (index route, email capture); sign-up/sign-in; idea submission; clarifying Qs screen; research progress screen; checkpoint screen; build progress screen; deliverables screen; Tailwind styling; navigation transitions correct |
| G-6  | QA           | `qa-report.md` + verdict (PASS / FAIL / PARTIAL) | All 7 screens render; auth flow works end-to-end; state machine transitions verified; mock data is realistic and domain-appropriate; `.env.example` complete; no dead code; no hardcoded credentials; README present with setup + "Extending to Production" section |
| G-7  | DevOps       | GitHub repo created + Vercel project deployed  | GitHub repo `unicorn-factory` created; code pushed; Vercel project configured with env vars; production deployment live; health check passes (`/api/health`) |

## Dependencies

- G-3 blocked by G-2 (needs spec.md)
- G-4 blocked by G-3 (needs architecture.md for project structure, schema, types)
- G-5 blocked by G-4 (needs API routes, TypeScript types, and state machine in place)
- G-6 blocked by G-4 + G-5 (needs full application to test)
- G-7 blocked by G-6 QA PASS (no deployment until QA clears)

## Pre-requisite Notes (flagged for user)

1. **Supabase project:** No Supabase project exists yet. The Backend-1 agent will include Supabase project setup instructions in the implementation, and the DevOps gate will configure the production env vars. User must create a free Supabase project at supabase.com before running G-4, or Backend-1 will include setup steps.
2. **ANTHROPIC_API_KEY:** Must be available in `.env` for the two real LLM calls. README will include setup instructions. User should obtain a key at console.anthropic.com before running the app locally.
3. **Vercel account + CLI:** Required for G-7. User should have Vercel CLI installed (`npm i -g vercel`) and be logged in (`vercel login`) before G-7 begins.
4. **GitHub repo:** Will be created from scratch by DevOps in G-7. Suggested name: `unicorn-factory`.
