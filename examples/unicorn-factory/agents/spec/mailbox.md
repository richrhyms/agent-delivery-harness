---
task-id: 2026-06-25-unicorn-factory-mvp-c3f2
agent: spec-specialist
assigned-by: cto
pm-approved: true
pm-approved-at: 2026-06-25T17:10:00Z
pm-note: Single-agent phase; CTO pre-approved per protocol (plan review at Gate 1 already established scope).
project: unicorn-factory
project-config: ~/.claude/orchestration/projects/unicorn-factory.md
---

## Task

Produce the functional specification (`spec.md`) for the Unicorn Factory MVP.

This spec will be consumed by the Architect in the next gate to design the project directory structure, Supabase schema DDL, state machine definition, component tree, API route map, and TypeScript type contracts. It must be complete enough that no design decisions are left ambiguous for the Architect or the Backend/Frontend engineers downstream.

## Input Files

- `~/.claude/orchestration/active/2026-06-25-unicorn-factory-mvp-c3f2/brief.md` — goal, constraints, 7-step primary flow, scope boundaries
- `~/.claude/orchestration/active/2026-06-25-unicorn-factory-mvp-c3f2/plan.md` — gate sequence and acceptance criteria
- Source requirements document: `~/projects/unicorn-factory/docs/unicorn-factory-requirements.md` (read if it exists; if it does not exist, derive the spec entirely from the brief)

## Expected Output

Write `spec.md` to:
  `~/.claude/orchestration/active/2026-06-25-unicorn-factory-mvp-c3f2/spec.md`

The spec must contain all of the following sections:

### 1. Screen Inventory
For each of the 7 screens in the MVP primary flow, provide:
- Screen name and route path
- Purpose (one sentence)
- Entry condition (what state or event brings the user here)
- Exit transitions (what actions move the user to the next screen)
- Key UI elements (form fields, buttons, dynamic content)
- Which data is real vs mocked (labelled clearly)

Screens to specify:
1. Landing page (`/`) — email capture form, "Get Started" CTA, value proposition copy
2. Sign-up / Sign-in (`/auth`) — email + password fields, Supabase Auth integration
3. Idea submission (`/idea`) — free-text input, LLM constraint check call, accept/reject branching
4. Clarifying questions (`/questions`) — display up to 3 LLM-generated questions, user answer inputs, submit
5. Research progress (`/research`) — step-by-step progress indicator, mock agent steps, auto-advance on completion
6. Human checkpoint (`/checkpoint`) — mock pain point signal, competitor map, go/no-go recommendation panel; "Proceed" and "Stop Here" buttons
7. Build progress (`/build`) — step-by-step progress indicator, mock build steps, auto-advance on completion
8. Deliverables (`/deliverables`) — display all 6 deliverables: research report, recommendation, requirements doc, live URL, GitHub link, growth strategy

### 2. Database Schema

Define the Supabase (PostgreSQL) tables required. For each table:
- Table name
- Column name, type, nullable, default, constraints
- Row Level Security (RLS) policy description

Minimum tables required:
- `email_leads` — for landing page email captures
- `projects` — one row per user idea submission, holds state machine status, idea text, clarifying Q&A, mock outputs
- Any Supabase Auth integration notes (auth.users is managed by Supabase — reference it but do not redefine it)

### 3. Project State Machine

Define the project status enum and valid transitions:

States (minimum): `idea_submitted` → `questions_answered` → `research_running` → `research_complete` → `checkpoint_reviewed` → `build_running` → `build_complete` → `stopped`

For each transition: trigger event, guard condition (if any), resulting state.

### 4. API Routes

For each Next.js API route (App Router format, `app/api/...`):
- Route path
- HTTP method
- Request body shape (TypeScript interface)
- Response body shape (TypeScript interface)
- Auth required (yes/no)
- Whether it calls LLM (real) or returns mock data (mocked)
- `// MOCK:` label for any mocked routes

Minimum routes required:
- `POST /api/leads` — save email lead
- `POST /api/projects` — create new project record
- `POST /api/projects/[id]/check-idea` — LLM constraint check (REAL)
- `POST /api/projects/[id]/questions` — LLM clarifying question generation (REAL)
- `POST /api/projects/[id]/submit-answers` — save answers, trigger research
- `POST /api/projects/[id]/research` — mock research execution (MOCK)
- `POST /api/projects/[id]/proceed` — user proceeds past checkpoint
- `POST /api/projects/[id]/stop` — user stops project
- `POST /api/projects/[id]/build` — mock build execution (MOCK)
- `GET /api/projects/[id]` — fetch project state and outputs
- `GET /api/health` — health check

### 5. LLM Prompt Contracts

For each of the two real LLM calls, define:
- Model: `claude-haiku-3` (Anthropic) via Vercel AI SDK
- System prompt (exact text)
- User prompt template (with `{{variable}}` placeholders)
- Expected output format (JSON schema or structured text)
- Failure handling: what happens if the LLM call fails or returns unexpected format

**Call 1 — Idea Constraint Check:**
- Input: user's raw idea text
- Purpose: determine if the idea is a tech product (accept) or not (decline with explanation)
- Output: `{ verdict: "accept" | "decline", reason: string }`

**Call 2 — Clarifying Question Generation:**
- Input: accepted idea text
- Purpose: generate up to 3 targeted clarifying questions to refine the idea
- Output: `{ questions: string[] }` (max 3 items)

### 6. Mock Data Definitions

Provide the full mock data payloads that will be returned by mocked routes and displayed on mocked screens. All mock data must use "a tool for freelancers to track invoices" as the seeded example idea.

Required mock payloads:
- Research agent steps (array of step objects with name, status, durationMs)
- Pain point signal (text summary)
- Competitor map (array of competitor objects: name, description, weakness)
- Go/no-go recommendation (verdict + rationale)
- Build agent steps (array of step objects)
- Research report (Markdown string, ~200 words)
- Recommendation document (Markdown string, ~150 words)
- Requirements document (Markdown string, ~300 words with user stories)
- Live MVP URL (mock string: `https://invoice-tracker-mvp.vercel.app`)
- GitHub link (mock string: `https://github.com/unicorn-factory/invoice-tracker-mvp`)
- Growth strategy (Markdown string, ~200 words)

### 7. Environment Variables

List every environment variable the application requires. For each:
- Variable name
- Purpose
- Example / placeholder value (never real credentials)
- Required vs optional

### 8. Scope Boundary Explicit List

Enumerate what is explicitly OUT of scope for the MVP, matching the brief constraints:
- Multi-project dashboard
- Parallel agent execution
- PDF export
- Real research agent execution
- Real build agent execution
- Any feature not part of the 7-step primary flow

## Acceptance Criteria

The gate-2.md file you write must confirm all of the following are present in spec.md:
- [ ] All 7 screens fully specified (8 routes including landing)
- [ ] Database schema with all required tables and RLS notes
- [ ] State machine with all states and transitions defined
- [ ] All API routes listed with request/response shapes
- [ ] Both LLM prompt contracts written with exact system prompt text
- [ ] Mock data payloads complete and using the seed example idea
- [ ] All environment variables enumerated
- [ ] Scope boundary list present

## Gate File to Write

After completing spec.md, write:
  `~/.claude/orchestration/active/2026-06-25-unicorn-factory-mvp-c3f2/gates/gate-2.md`

Use this format:

```
---
task-id: 2026-06-25-unicorn-factory-mvp-c3f2
gate: 2
label: Spec Approval
written-by: spec-specialist
status: pending
---

## What Was Done
<summary of spec written>

## Deliverable
spec.md at ~/.claude/orchestration/active/2026-06-25-unicorn-factory-mvp-c3f2/spec.md

## Acceptance Criteria Met
- [x/[ ]] All 7 screens fully specified
- [x/[ ]] Database schema defined
- [x/[ ]] State machine defined
- [x/[ ]] All API routes listed with shapes
- [x/[ ]] Both LLM prompt contracts written
- [x/[ ]] Mock data payloads complete
- [x/[ ]] Environment variables enumerated
- [x/[ ]] Scope boundary list present

## Issues / Gaps Found
<any ambiguities resolved or assumptions made>
```
