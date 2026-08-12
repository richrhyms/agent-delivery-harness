---
task-id: 2026-06-25-unicorn-factory-mvp-c3f2
gate: 0
label: Understanding Confirmation
written-by: cto
status: approved
approved-at: 2026-06-25T16:45:00Z
---

## What Was Done
Reviewed the brief for the Unicorn Factory MVP task. Composed an understanding of the goal, scope, and key constraints.

## Deliverable
Understanding restatement below.

## Acceptance Criteria Met
- [ ] Goal is accurately captured
- [ ] Scope boundaries are stated
- [ ] Assumptions are explicit

## Next Phase (if approved)
CTO produces formal Plan → PM vets → Gate 1 presented for approval.

---

## Understanding Restatement

**Goal:** Build an MVP of the Unicorn Factory — a Next.js + Supabase web application that guides a user through a 7-step flow: sign up, submit a tech idea (with LLM constraint check), answer LLM-generated clarifying questions, watch a mock research progress screen, reach a human go/no-go checkpoint, watch a mock build progress screen, and finally view a deliverables screen showing 6 mock outputs. Real auth and two real LLM calls (constraint check + clarifying questions); everything else is mocked with realistic domain-appropriate data.

**Scope includes:**
- 7-step primary user flow (all 7 screens, all navigation transitions)
- Supabase Auth (email + password sign-up and sign-in)
- Supabase database (project state machine — tracks which step a user's idea is at)
- Landing page as the index route (email capture stored in Supabase)
- Two real Anthropic Claude Haiku calls via Vercel AI SDK: (1) idea constraint check, (2) clarifying question generation (up to 3 questions)
- Mock research and build progress screens (step-by-step indicators, realistic mock data)
- Human checkpoint screen with mock pain point signal, competitor map, and go/no-go recommendation — user chooses Proceed or Stop
- Deliverables screen with 6 mock outputs (research report, recommendation, requirements doc, live URL, GitHub link, growth strategy) — all well-formatted Markdown display
- All mock sections labelled `// MOCK:` in code
- Mock seed data based on "a tool for freelancers to track invoices"
- `.env.example`, `.gitignore`, README with setup and "Extending to Production" section
- TypeScript throughout (no `any`), modular structure, no dead code
- Vercel deployment (free tier)

**Scope excludes / assumptions:**
- No multi-project dashboard — single user flow only
- No live research or build agent execution — all mocked
- No PDF export — Markdown display only
- No parallel agent execution — sequential only
- No staging environment — dev via Vercel preview, prod via Vercel production
- No existing GitHub repo or Supabase project — both will be created during the DevOps gate; repo name suggestion: `unicorn-factory`
- ANTHROPIC_API_KEY will be provided via `.env` — README will include setup instructions
- Vercel CLI access is assumed available (or will be set up as a DevOps pre-requisite)
- The project directory is `~/projects/unicorn-factory/` — this will be the local workspace

---
Type `/orch-approve` to confirm, or `/orch-approve reject <feedback>` to correct me before I plan.
