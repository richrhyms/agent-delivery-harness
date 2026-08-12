---
task-id: 2026-06-25-unicorn-factory-mvp-c3f2
written-by: spec-specialist
status: draft
---

## Problem Statement

Unicorn Factory is a web platform that takes a user's tech product idea from raw concept to a deployed proof-of-concept by running an autonomous multi-agent pipeline. The MVP demonstrates the full end-to-end 7-screen user flow — from sign-up through idea submission, AI-powered clarifying questions, mocked research and build phases, a human go/no-go checkpoint, and a deliverables display — using real Supabase authentication, real LLM calls for intake intelligence, and realistic mock data for all pipeline outputs.

---

## 1. Screen Inventory

### Screen 1 — Landing Page

- **Route:** `/`
- **Purpose:** Introduce the platform value proposition and capture visitor email before sign-up.
- **Entry condition:** Any unauthenticated visitor arriving at the root URL.
- **Exit transitions:**
  - Email submitted → email stored in `email_leads`; user remains on page with confirmation message.
  - "Get Started" CTA clicked → navigate to `/auth`.
- **Key UI elements:**
  - Headline: "Turn your idea into a working MVP — overnight."
  - Sub-headline: "Unicorn Factory runs an autonomous AI pipeline that researches your market, builds your product, and ships it."
  - Email capture form: single input (`email`) + "Notify Me" button.
  - "Get Started" CTA button → `/auth`.
  - Feature highlights section (3 bullet points about the pipeline).
- **Data:** Email capture is REAL (stored in Supabase). All copy is static.

---

### Screen 2 — Sign-Up / Sign-In

- **Route:** `/auth`
- **Purpose:** Authenticate the user via Supabase Auth (email + password).
- **Entry condition:** User clicks "Get Started" from landing page, or navigates to `/auth` directly.
- **Exit transitions:**
  - Successful sign-up → redirect to `/idea`.
  - Successful sign-in → redirect to `/idea` (or `/deliverables` if user has a completed project).
  - Auth error → error message displayed inline; stay on `/auth`.
- **Key UI elements:**
  - Tab switcher: "Sign Up" / "Sign In".
  - Email input field.
  - Password input field.
  - Submit button: "Create Account" (sign-up) / "Sign In" (sign-in).
  - Inline validation error messages.
  - Link back to `/`.
- **Data:** REAL — Supabase Auth handles all credential management. No credentials stored in application DB.

---

### Screen 3 — Idea Submission

- **Route:** `/idea`
- **Purpose:** Accept the user's free-text product idea, run an LLM constraint check, and accept or reject the idea.
- **Entry condition:** Authenticated user. No active project in a non-terminal state for this user.
- **Exit transitions:**
  - LLM verdict = `accept` → create project record (status: `idea_submitted`), navigate to `/questions`.
  - LLM verdict = `decline` → display decline reason inline; user may revise and resubmit.
  - Sign-out → `/auth`.
- **Key UI elements:**
  - Page title: "What's your idea?"
  - Textarea: "Describe your product idea in a few sentences" (min 20 chars, max 500 chars).
  - "Submit Idea" button — triggers LLM constraint check (loading state while waiting).
  - Decline banner (conditional): shows `reason` from LLM response; "Try a different idea" link clears the field.
  - Accept state: brief success message before redirect.
- **Data:** Idea text and LLM response are REAL. Project record creation is REAL.

---

### Screen 4 — Clarifying Questions

- **Route:** `/questions`
- **Purpose:** Present up to 3 LLM-generated clarifying questions about the accepted idea; collect user answers.
- **Entry condition:** Project in state `idea_submitted`. User navigated here after idea acceptance.
- **Exit transitions:**
  - All questions answered + "Submit" clicked → answers saved to project, status transitions to `questions_answered`, research pipeline triggered (status → `research_running`), navigate to `/research`.
  - Sign-out → `/auth`.
- **Key UI elements:**
  - Page title: "A few quick questions"
  - Sub-title: "Help us understand your idea better."
  - Up to 3 question cards, each with:
    - Question text (LLM-generated).
    - Single-line text input for the answer.
  - "Continue" / "Submit Answers" button (disabled until all fields filled).
  - Loading spinner while questions are being fetched on mount.
- **Data:** Questions are REAL (LLM-generated on mount via `GET /api/projects/[id]/questions`). Answers are REAL (saved to Supabase).

---

### Screen 5 — Research Progress

- **Route:** `/research`
- **Purpose:** Display a step-by-step indicator of the mock research pipeline running; auto-advance to checkpoint when complete.
- **Entry condition:** Project in state `research_running`.
- **Exit transitions:**
  - All mock steps complete → status transitions to `research_complete`, auto-navigate to `/checkpoint`.
  - Sign-out → `/auth`.
- **Key UI elements:**
  - Page title: "Researching your market..."
  - Animated step list (sequential, each step checks off as it "completes"):
    1. Identifying target audience
    2. Scanning competitor landscape
    3. Analysing pain point signals
    4. Generating market opportunity report
    5. Compiling go/no-go recommendation
  - Each step shows: step name, status icon (pending / running / complete), mock duration label.
  - Auto-advance: after the final step marks complete (~3–5 seconds per step via setTimeout), navigate to `/checkpoint`.
- **Data:** MOCK — all step timings and outputs are seeded. `// MOCK: Research agent pipeline — replace with real agent orchestration calls.`

---

### Screen 6 — Human Checkpoint

- **Route:** `/checkpoint`
- **Purpose:** Present the mock research findings and let the user decide to proceed with the build or stop.
- **Entry condition:** Project in state `research_complete`.
- **Exit transitions:**
  - "Proceed to Build" clicked → status transitions to `checkpoint_reviewed`, then `build_running`, navigate to `/build`.
  - "Stop Here" clicked → status transitions to `stopped`, navigate to a "Project Stopped" terminal screen (rendered at `/checkpoint` with a stopped state indicator, no separate route needed).
  - Sign-out → `/auth`.
- **Key UI elements:**
  - Page title: "Research Complete — Your Checkpoint"
  - **Pain Point Signal panel:** text summary of validated pain points.
  - **Competitor Map panel:** table of 3 competitors (name, description, key weakness).
  - **Go/No-Go Recommendation panel:** verdict badge ("GO" or "NO-GO") + rationale paragraph.
  - Two action buttons:
    - "Proceed to Build" (primary, green).
    - "Stop Here" (secondary, neutral/red).
  - Stopped state: replaces buttons with "Project stopped. Your research report is saved." message.
- **Data:** MOCK — all three panels are seeded mock data. `// MOCK: Replace pain_point_signal, competitor_map, and recommendation with real research agent output.`

---

### Screen 7 — Build Progress

- **Route:** `/build`
- **Purpose:** Display a step-by-step indicator of the mock build pipeline running; auto-advance to deliverables when complete.
- **Entry condition:** Project in state `build_running`.
- **Exit transitions:**
  - All mock steps complete → status transitions to `build_complete`, auto-navigate to `/deliverables`.
  - Sign-out → `/auth`.
- **Key UI elements:**
  - Page title: "Building your MVP..."
  - Animated step list (sequential):
    1. Scaffolding project structure
    2. Implementing core features
    3. Writing automated tests
    4. Deploying to Vercel
    5. Configuring GitHub repository
    6. Generating documentation
  - Same step indicator UX as research progress screen.
  - Auto-advance on all steps complete.
- **Data:** MOCK — all step timings seeded. `// MOCK: Build agent pipeline — replace with real build agent orchestration calls.`

---

### Screen 8 — Deliverables

- **Route:** `/deliverables`
- **Purpose:** Display all 6 MVP deliverables generated by the (mock) build pipeline.
- **Entry condition:** Project in state `build_complete`.
- **Exit transitions:**
  - None within the flow. This is the terminal success screen.
  - Sign-out → `/auth`.
- **Key UI elements:**
  - Page title: "Your MVP is Ready"
  - Six deliverable cards:
    1. **Research Report** — rendered Markdown block (~200 words).
    2. **Recommendation** — rendered Markdown block (~150 words).
    3. **Requirements Document** — rendered Markdown block (~300 words with user stories).
    4. **Live MVP URL** — clickable link badge: `https://invoice-tracker-mvp.vercel.app`.
    5. **GitHub Repository** — clickable link badge: `https://github.com/unicorn-factory/invoice-tracker-mvp`.
    6. **Growth Strategy** — rendered Markdown block (~200 words).
  - "Share" or "Copy link" affordance (optional, nice-to-have, not required for MVP).
- **Data:** MOCK — all 6 deliverable contents are seeded. `// MOCK: Replace deliverables with real build agent outputs stored in projects.outputs column.`

---

## 2. Database Schema

### Table: `email_leads`

```sql
CREATE TABLE email_leads (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email       TEXT NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- RLS: No authenticated user needed. Insert allowed from service role only (via API route).
-- No select policy for end users — leads are admin-only.
ALTER TABLE email_leads ENABLE ROW LEVEL SECURITY;
-- Policy: allow insert from authenticated service role (API route uses service key)
```

### Table: `projects`

```sql
CREATE TABLE projects (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status              TEXT NOT NULL DEFAULT 'idea_submitted',
                      -- enum: idea_submitted | questions_answered | research_running |
                      --        research_complete | checkpoint_reviewed | build_running |
                      --        build_complete | stopped
  idea_text           TEXT NOT NULL,
  clarifying_questions JSONB,
  -- Shape: [{ question: string, answer: string | null }]
  outputs             JSONB,
  -- Shape: see Mock Data Definitions section for full structure
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE projects ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users may only read/write their own rows.
CREATE POLICY "Users own their projects"
  ON projects
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
```

### Supabase Auth Integration Notes

- `auth.users` is managed entirely by Supabase. Do not create a separate `users` table.
- `projects.user_id` references `auth.users(id)` to link projects to authenticated users.
- Row-level security is enforced at the DB layer using `auth.uid()` from the Supabase JWT.
- API routes that write to `projects` must use the **anon key** with the user's JWT in the Authorization header to respect RLS.
- API routes that write to `email_leads` must use the **service role key** (server-side only, never exposed to client).

---

## 3. Project State Machine

### Status Enum

```
idea_submitted
questions_answered
research_running
research_complete
checkpoint_reviewed
build_running
build_complete
stopped
```

### Transitions

| From State           | Trigger Event                              | Guard Condition                        | To State              |
|----------------------|--------------------------------------------|----------------------------------------|-----------------------|
| _(none)_             | POST /api/projects (idea accepted by LLM)  | LLM verdict = "accept"                 | `idea_submitted`      |
| `idea_submitted`     | POST /api/projects/[id]/submit-answers     | All clarifying answers present         | `questions_answered`  |
| `questions_answered` | POST /api/projects/[id]/research (trigger) | Automatic after answer submission      | `research_running`    |
| `research_running`   | POST /api/projects/[id]/research (complete)| Mock pipeline completes (client-side)  | `research_complete`   |
| `research_complete`  | POST /api/projects/[id]/proceed            | User clicks "Proceed to Build"         | `checkpoint_reviewed` |
| `research_complete`  | POST /api/projects/[id]/stop               | User clicks "Stop Here"                | `stopped`             |
| `checkpoint_reviewed`| POST /api/projects/[id]/build (trigger)    | Automatic after proceed                | `build_running`       |
| `build_running`      | POST /api/projects/[id]/build (complete)   | Mock pipeline completes (client-side)  | `build_complete`      |

`stopped` and `build_complete` are terminal states. No transitions out.

---

## 4. API Routes

### `POST /api/leads`

- Auth required: No
- LLM: No
- Notes: Writes to `email_leads` using service role key. Returns 400 on invalid email.

### `POST /api/projects`

- Auth required: Yes (Supabase JWT)
- LLM: Yes — calls LLM constraint check (Call 1). Creates project row only on accept.

### `GET /api/projects/[id]/questions`

- Auth required: Yes
- LLM: Yes — calls LLM clarifying question generation (Call 2) on first fetch.

### `POST /api/projects/[id]/submit-answers`

- Auth required: Yes
- LLM: No
- Notes: Validates project is in `idea_submitted` state. Saves answers. Transitions to `questions_answered`.

### `POST /api/projects/[id]/research`

- Auth required: Yes
- LLM: No — MOCK
- `// MOCK: This route simulates the research agent pipeline.`

### `POST /api/projects/[id]/proceed`

- Auth required: Yes
- Notes: Validates project is in `research_complete` state. Transitions to `checkpoint_reviewed`.

### `POST /api/projects/[id]/stop`

- Auth required: Yes
- Notes: Validates project is in `research_complete` state. Transitions to `stopped`.

### `POST /api/projects/[id]/build`

- Auth required: Yes
- LLM: No — MOCK
- `// MOCK: This route simulates the build agent pipeline.`

### `GET /api/projects/[id]`

- Auth required: Yes
- Notes: Returns 403 if project does not belong to user.

### `GET /api/health`

- Auth required: No
- Notes: Always returns 200 with `{ status: "ok" }`.

---

## 5. LLM Prompt Contracts

**SDK:** Vercel AI SDK (`ai` package) with `@ai-sdk/anthropic` provider.
**Model:** `claude-haiku-4-5` (use `ANTHROPIC_MODEL` env var for override)

### Call 1 — Idea Constraint Check

**System prompt (exact text):**
```
You are an intake classifier for a software MVP factory. Your job is to determine whether a user's idea is a technology product that can be built as a web or mobile application MVP.

Accept ideas that are: web apps, mobile apps, SaaS tools, APIs, developer tools, e-commerce platforms, marketplaces, productivity software, data tools, or any software-based product.

Decline ideas that are: physical products, services without a software component, vague concepts that cannot be built as software, illegal or harmful applications, or ideas that are not products at all (e.g. "I want to make money").

Respond ONLY with a JSON object in this exact format, with no additional text:
{"verdict":"accept","reason":"Brief reason why this is a valid tech product idea."} 
or
{"verdict":"decline","reason":"Brief explanation of why this idea cannot be built as a software MVP, and what type of idea would be accepted."}
```

**User prompt template:**
```
User idea: {{ideaText}}
```

### Call 2 — Clarifying Question Generation

**System prompt (exact text):**
```
You are a product discovery assistant for a software MVP factory. Given a user's tech product idea, generate exactly 3 concise clarifying questions that will help the engineering team build the right MVP.

Focus your questions on: target user, core differentiator, and primary success metric. Questions should be short (under 20 words each), concrete, and directly answerable by a non-technical user.

Respond ONLY with a JSON object in this exact format, with no additional text:
{"questions":["Question 1?","Question 2?","Question 3?"]}
```

**User prompt template:**
```
Product idea: {{ideaText}}
```

---

## 6. Mock Data Definitions

All mock data uses "a tool for freelancers to track invoices" as the seeded example idea.

(Full mock data payloads are defined in `lib/mock-data.ts` — see architecture.md Section 10 for the complete TypeScript constants.)

---

## 7. Environment Variables

| Variable                    | Purpose                                                    | Example Value                        | Required |
|-----------------------------|------------------------------------------------------------|--------------------------------------|----------|
| `NEXT_PUBLIC_SUPABASE_URL`  | Supabase project URL (used client-side)                    | `https://xyzabc.supabase.co`         | Yes      |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase anon/public key (safe to expose)             | `eyJhbGci...`                        | Yes      |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase service role key (server-side only)               | `eyJhbGci...`                        | Yes      |
| `ANTHROPIC_API_KEY`         | Anthropic API key for LLM calls                            | `sk-ant-api03-...`                   | Yes      |
| `ANTHROPIC_MODEL`           | Anthropic model ID (allows swapping without code change)   | `claude-haiku-4-5`                   | No       |

---

## 8. Scope Boundary — Explicit Exclusions

| Feature                         | Reason for exclusion                                                   |
|---------------------------------|------------------------------------------------------------------------|
| Multi-project dashboard         | Single user flow only (scope ceiling rule from brief)                  |
| Parallel agent execution        | Agent runs are sequential in MVP (brief constraint)                    |
| PDF export of deliverables      | Markdown display is sufficient; no PDF tooling required                |
| Real research agent execution   | Mocked — research pipeline is simulated with seeded data               |
| Real build agent execution      | Mocked — build pipeline is simulated with seeded data                  |
| Real competitor API calls       | Competitor data is seeded mock data                                    |
| Stripe / payment integration    | The platform itself does not take payments in MVP                      |
| Multi-user orgs / team access   | Single user per account only                                           |
| Email notifications             | No email sending from the platform                                     |
| User profile / settings screen  | Not part of the 7-step primary flow                                    |
| Project history / list view     | Single active project per user in MVP                                  |
| Admin dashboard                 | No internal tooling scope                                              |
| i18n / localisation             | English only                                                           |
| Accessibility (WCAG AA)         | Recommended but not a gating requirement for MVP                       |
| Dark mode                       | Single theme; no toggle required                                       |

---

## Source References

- `~/.claude/orchestration/active/2026-06-25-unicorn-factory-mvp-c3f2/brief.md`
- `~/.claude/orchestration/active/2026-06-25-unicorn-factory-mvp-c3f2/plan.md`
- `~/projects/unicorn-factory/docs/unicorn-factory-requirements.md` — file does not exist; spec derived entirely from brief.
