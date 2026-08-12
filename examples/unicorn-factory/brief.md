---
task-id: 2026-06-25-unicorn-factory-mvp-c3f2
project: unicorn-factory
created: 2026-06-25
input-type: filepath
source: docs/unicorn-factory-requirements.md
status: complete
---

## Goal

Build an MVP of the Unicorn Factory — an autonomous multi-agent web platform that takes a tech product idea from raw concept to a deployed proof-of-concept. The MVP demonstrates the complete end-to-end user flow (sign up → idea submission with clarifying questions → mock research phase → human go/no-go checkpoint → mock build phase → deliverables screen) using real authentication and real LLM calls at intake, with all agent pipelines mocked using realistic domain-appropriate data.

## Known Context

- Full requirements document: `docs/unicorn-factory-requirements.md` (14 sections, covers full vision and explicit MVP scope)
- Project directory: `~/projects/unicorn-factory/`
- Stack (fixed): Next.js (App Router, TypeScript) + Supabase (auth + database) + Vercel (hosting) + Tailwind CSS
- AI: Anthropic Claude Haiku via Vercel AI SDK — used for two real calls only: (1) idea constraint check, (2) clarifying question generation
- The Unicorn Factory builds MVPs for users' ideas — the MVP of the platform itself uses the same stack it would generate for users
- Mock data seed: all mock research and deliverable outputs must use "a tool for freelancers to track invoices" as the example idea

**MVP Primary Flow (7 steps, no more):**
1. Sign up (email + password via Supabase Auth)
2. Submit idea (free text → LLM constraint check → accept or decline non-tech ideas)
3. Clarifying questions (LLM generates up to 3; user answers)
4. Research progress screen (step-by-step indicator; mock data underneath — no live API calls)
5. Human checkpoint screen (mock pain point signal, competitor map, go/no-go recommendation; user chooses Proceed or Stop)
6. Build progress screen (step-by-step indicator; mock deliverables generated underneath)
7. Deliverables screen (all 6 deliverables displayed: research report, recommendation, requirements doc, live URL, GitHub link, growth strategy — all mock, all well-formatted)

**What is real:** Auth, project state machine, idea submission, LLM constraint check, LLM clarifying questions, all UI screens and navigation, email capture on landing page (stored in Supabase), "Stop Here" ending a project.

**What is mocked (// MOCK: labelled):** Research agent execution, build agent execution, live MVP URL, GitHub repository link.

## Constraints

- Stack is non-negotiable: Next.js (TypeScript) + Supabase + Vercel + Tailwind CSS
- MVP scope is exactly the 7-step primary flow — nothing outside this is in scope
- All mock sections must be labelled `// MOCK:` in code with a comment explaining what a production implementation replaces
- Mock data must be realistic and domain-appropriate (not lorem ipsum) — seed example: "a tool for freelancers to track invoices"
- Code quality: boilerplate-grade — TypeScript throughout (no `any`), modular structure, no dead code, `.env.example` included, `.gitignore` covers `.env`, README with setup instructions and "Extending to Production" section
- No hardcoded credentials anywhere in the codebase
- No PDF export required — Markdown display sufficient
- Single user flow only (scope ceiling rule — no multi-project dashboard)
- Agent runs are sequential in MVP (not parallel)
- Landing page is part of the application (index route) — not a separate deployment

## Open Questions

- Anthropic API key: will need `ANTHROPIC_API_KEY` in `.env` — CTO should confirm this is available or provide setup instructions in the README
- Vercel deployment: the DevOps gate will need a Vercel account and CLI access — CTO should flag if this needs to be set up before the build phase
- GitHub repository: no repo exists yet — will be created during the DevOps gate; name suggestion: `unicorn-factory`
- Supabase project: no Supabase project exists yet — CTO should include Supabase project setup as a pre-requisite step in the plan
