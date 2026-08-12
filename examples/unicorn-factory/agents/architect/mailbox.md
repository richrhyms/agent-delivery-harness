---
task-id: 2026-06-25-unicorn-factory-mvp-c3f2
agent: architect
gate: 3
assigned-by: cto
assigned-at: 2026-06-25T17:10:00Z
pm-approved: true
pm-approved-at: 2026-06-25T17:10:00Z
project: unicorn-factory
project-config: ~/.claude/orchestration/projects/unicorn-factory.md
---

## Task

Produce an architecture document (`architecture.md`) for the Unicorn Factory MVP. This document will be the primary reference for the Backend-1 and Frontend-1 engineers who implement the application in G-4 and G-5. It must be detailed enough that both agents can work from it without needing to re-read the spec.

## Input Files

- `~/.claude/orchestration/active/2026-06-25-unicorn-factory-mvp-c3f2/spec.md` — complete functional spec (8 screens, DB schema, state machine, 11 API routes, 2 LLM prompt contracts, mock data definitions, env vars, scope exclusions)
- `~/.claude/orchestration/active/2026-06-25-unicorn-factory-mvp-c3f2/brief.md` — original brief with stack constraints and project directory
- `~/.claude/orchestration/projects/unicorn-factory.md` — project config

## Stack (non-negotiable)

- **Framework:** Next.js 14+ with App Router, TypeScript
- **Auth + DB:** Supabase (Auth + PostgreSQL)
- **Styling:** Tailwind CSS
- **Hosting:** Vercel
- **AI SDK:** Vercel AI SDK (`ai` package) with `@ai-sdk/anthropic` provider
- **Project directory:** `~/projects/unicorn-factory/`

## Expected Output

Write `~/.claude/orchestration/active/2026-06-25-unicorn-factory-mvp-c3f2/architecture.md` containing all of the following sections:

### 1. Project Directory Structure
Complete file/folder tree for the Next.js App Router project. Must include:
- `app/` route directories for all 8 routes: `/`, `/auth`, `/idea`, `/questions`, `/research`, `/checkpoint`, `/build`, `/deliverables`
- `app/api/` route handlers for all 11 API routes from spec
- `lib/` for shared utilities (Supabase client, AI client, mock data)
- `types/` for TypeScript type definitions
- `components/` for shared UI components
- `.env.example`, `README.md`, `.gitignore`

### 2. Supabase Schema DDL
Complete, runnable SQL to execute in the Supabase SQL editor:
- `email_leads` table with RLS
- `projects` table with RLS and correct policy
- Any indexes that would help performance
- `updated_at` trigger if needed

### 3. TypeScript Type Contracts
Complete TypeScript interfaces/types to place in `types/index.ts`:
- `ProjectStatus` enum/union type — all 8 states
- `Project` interface — all columns from DB schema
- `ProjectOutputs` interface — research and build output shapes
- `Competitor` interface
- All API request/response interfaces from spec (16 total)
- `MockStep` interface for progress screens

### 4. State Machine Definition
A clear mapping (can be a TypeScript object or table) showing:
- All 8 states
- All valid transitions (from → to + trigger)
- Guard conditions
- Terminal states (`stopped`, `build_complete`)
This will be used by the Backend-1 engineer to implement state validation in API routes.

### 5. Component Tree
A hierarchical list of all React components needed:
- Page components (one per route)
- Shared layout components
- Feature components (ProgressTracker, CompetitorTable, DeliverableCard, etc.)
- For each component: props interface name and which page(s) use it

### 6. API Route Map
For each of the 11 API routes, specify:
- File path in `app/api/`
- HTTP method
- Auth requirement (and how auth is checked — Supabase session from headers)
- Which Supabase client to use (anon client vs service role client)
- State guard (if applicable — which status the project must be in)
- What it writes/reads from DB

### 7. Supabase Client Setup
How to initialise the Supabase client(s) in Next.js App Router:
- `lib/supabase/client.ts` — browser client (anon key)
- `lib/supabase/server.ts` — server-side client for API routes (reads JWT from request headers)
- `lib/supabase/service.ts` — service role client (for `email_leads` writes only)
- Note the correct packages: `@supabase/supabase-js` and `@supabase/ssr`

### 8. AI Client Setup
How to initialise the Vercel AI SDK in `lib/ai/client.ts`:
- Import pattern for `@ai-sdk/anthropic`
- Model instantiation using `ANTHROPIC_MODEL` env var with `claude-haiku-4-5` default
- `generateText` call pattern with error handling and retry logic

### 9. Navigation and Auth Guard
How route protection works in App Router:
- Middleware file (`middleware.ts`) to redirect unauthenticated users from protected routes to `/auth`
- Protected routes: `/idea`, `/questions`, `/research`, `/checkpoint`, `/build`, `/deliverables`
- Public routes: `/`, `/auth`
- State routing logic: on sign-in, redirect user to the correct screen for their current project status

### 10. Mock Data Module
Specify `lib/mock-data.ts` as a single file exporting all mock constants:
- All 11 mock payloads from spec (reference the spec's exact const names and shapes)
- Each export must have its `// MOCK:` label
- This file is the ONLY place mock data lives — API routes import from here

## Acceptance Criteria

- [ ] Directory structure covers all 8 routes and all 11 API route files
- [ ] Supabase DDL is complete and runnable (both tables, RLS, indexes, trigger)
- [ ] TypeScript types cover all entities and all API shapes — no `any`
- [ ] State machine table includes all 8 states and all 8 transitions with guards
- [ ] Component tree lists all components with their props interface names
- [ ] API route map specifies auth method, DB client, and state guard for each of the 11 routes
- [ ] Supabase client initialisation covers all 3 client variants (browser, server, service)
- [ ] AI client setup includes model env var pattern and error handling approach
- [ ] Middleware auth guard covers all 6 protected routes
- [ ] Mock data module structure specified with all exports named

## Output Gate File

Write `~/.claude/orchestration/active/2026-06-25-unicorn-factory-mvp-c3f2/gates/gate-3.md` upon completion using this template:

```markdown
---
task-id: 2026-06-25-unicorn-factory-mvp-c3f2
gate: 3
label: Design Approval
written-by: architect
status: pending
approved-at:
---

## What Was Done
[description]

## Deliverable
`~/.claude/orchestration/active/2026-06-25-unicorn-factory-mvp-c3f2/architecture.md`

## Acceptance Criteria Met
- [ ] ... (list each item from mailbox acceptance criteria above, checked or unchecked)

## Issues / Gaps Found
[any issues, or "None"]

---
Type `/orch-approve` to confirm architecture and proceed to G-4 (Backend-1), or `/orch-approve reject <feedback>` to revise.
```
