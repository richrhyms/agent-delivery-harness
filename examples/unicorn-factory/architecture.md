---
task-id: 2026-06-25-unicorn-factory-mvp-c3f2
written-by: architect
status: draft
---

## Architecture Overview

Unicorn Factory MVP is a Next.js 14 App Router application with Supabase for auth and persistence, Tailwind CSS for styling, and Vercel AI SDK for two LLM calls. The application is a single-user, sequential 7-screen flow driven by a server-authoritative state machine stored in the `projects` table. All mock pipeline data lives in a single `lib/mock-data.ts` module imported by API route handlers.

---

## 1. Project Directory Structure

```
~/projects/unicorn-factory/
├── app/
│   ├── layout.tsx
│   ├── page.tsx                          # Screen 1: Landing page (/)
│   ├── auth/page.tsx                     # Screen 2: Sign-up / Sign-in (/auth)
│   ├── idea/page.tsx                     # Screen 3: Idea submission (/idea)
│   ├── questions/page.tsx                # Screen 4: Clarifying questions (/questions)
│   ├── research/page.tsx                 # Screen 5: Research progress (/research)
│   ├── checkpoint/page.tsx               # Screen 6: Human checkpoint (/checkpoint)
│   ├── build/page.tsx                    # Screen 7: Build progress (/build)
│   ├── deliverables/page.tsx             # Screen 8: Deliverables (/deliverables)
│   └── api/
│       ├── health/route.ts               # GET /api/health
│       ├── leads/route.ts                # POST /api/leads
│       ├── projects/route.ts             # POST /api/projects
│       └── projects/[id]/
│           ├── route.ts                  # GET /api/projects/[id]
│           ├── questions/route.ts        # GET /api/projects/[id]/questions
│           ├── submit-answers/route.ts   # POST /api/projects/[id]/submit-answers
│           ├── research/route.ts         # POST /api/projects/[id]/research
│           ├── proceed/route.ts          # POST /api/projects/[id]/proceed
│           ├── stop/route.ts             # POST /api/projects/[id]/stop
│           └── build/route.ts            # POST /api/projects/[id]/build
├── components/
│   ├── ui/
│   │   ├── Button.tsx
│   │   ├── Card.tsx
│   │   ├── Input.tsx
│   │   ├── Textarea.tsx
│   │   ├── Badge.tsx
│   │   ├── Spinner.tsx
│   │   └── ErrorBanner.tsx
│   ├── ProgressTracker.tsx
│   ├── CompetitorTable.tsx
│   ├── DeliverableCard.tsx
│   └── MarkdownRenderer.tsx
├── lib/
│   ├── supabase/
│   │   ├── client.ts
│   │   ├── server.ts
│   │   └── service.ts
│   ├── ai/client.ts
│   ├── mock-data.ts
│   └── state-machine.ts
├── types/index.ts
├── proxy.ts                              # Auth guard (Next.js 16 — renamed from middleware.ts)
├── .env.example
├── .gitignore
├── next.config.ts
├── tsconfig.json
├── package.json
└── README.md
```

---

## 2. Supabase Schema DDL

```sql
CREATE TABLE IF NOT EXISTS email_leads (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email      TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE email_leads ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS projects (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id              UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status               TEXT NOT NULL DEFAULT 'idea_submitted'
                         CHECK (status IN (
                           'idea_submitted', 'questions_answered', 'research_running',
                           'research_complete', 'checkpoint_reviewed', 'build_running',
                           'build_complete', 'stopped'
                         )),
  idea_text            TEXT NOT NULL,
  clarifying_questions JSONB,
  outputs              JSONB,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users own their projects" ON projects FOR ALL
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE INDEX IF NOT EXISTS projects_user_id_idx ON projects (user_id);
CREATE INDEX IF NOT EXISTS projects_status_idx ON projects (status);

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER projects_updated_at
  BEFORE UPDATE ON projects FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

---

## 3. TypeScript Type Contracts

(Full contents of `types/index.ts` — see the active task's architecture.md for the complete file. Key types: `ProjectStatus`, `Project`, `ProjectOutputs`, `Competitor`, `MockStep`, all API request/response interfaces.)

---

## 4. State Machine Definition

| From | To | Trigger | Guard |
|------|----|---------|-------|
| (none) | `idea_submitted` | POST /api/projects | LLM verdict = accept |
| `idea_submitted` | `questions_answered` | POST .../submit-answers | All answers filled |
| `questions_answered` | `research_running` | POST .../research phase=start | Status = questions_answered |
| `research_running` | `research_complete` | POST .../research phase=complete | Status = research_running |
| `research_complete` | `checkpoint_reviewed` | POST .../proceed | Status = research_complete |
| `research_complete` | `stopped` | POST .../stop | Status = research_complete |
| `checkpoint_reviewed` | `build_running` | POST .../build phase=start | Status = checkpoint_reviewed |
| `build_running` | `build_complete` | POST .../build phase=complete | Status = build_running |

`stopped` and `build_complete` are terminal — no outbound transitions.

---

## 5. Component Tree

See active task's architecture.md Section 5 for full hierarchy with props interface definitions.

Key components:
- `ProgressTrackerProps` — steps: MockStep[], onComplete: () => void, title: string, subtitle?: string
- `CompetitorTableProps` — competitors: Competitor[]
- `DeliverableCardProps` — title: string, type: 'markdown' | 'link', content: string
- `MarkdownRendererProps` — content: string
- `ButtonProps` — variant: 'primary' | 'secondary' | 'destructive', children, onClick, disabled, type, className

---

## 6. API Route Map

| Route File | Method | Auth | Supabase Client | State Guard |
|-----------|--------|------|-----------------|-------------|
| `app/api/health/route.ts` | GET | No | None | None |
| `app/api/leads/route.ts` | POST | No | service.ts | None |
| `app/api/projects/route.ts` | POST | Yes | server.ts | None |
| `app/api/projects/[id]/route.ts` | GET | Yes | server.ts | None |
| `app/api/projects/[id]/questions/route.ts` | GET | Yes | server.ts | idea_submitted or cached |
| `app/api/projects/[id]/submit-answers/route.ts` | POST | Yes | server.ts | idea_submitted |
| `app/api/projects/[id]/research/route.ts` | POST | Yes | server.ts | start: questions_answered; complete: research_running |
| `app/api/projects/[id]/proceed/route.ts` | POST | Yes | server.ts | research_complete |
| `app/api/projects/[id]/stop/route.ts` | POST | Yes | server.ts | research_complete |
| `app/api/projects/[id]/build/route.ts` | POST | Yes | server.ts | start: checkpoint_reviewed; complete: build_running |

---

## 7. Supabase Client Setup

- `lib/supabase/client.ts` — `createBrowserClient` from `@supabase/ssr` — used in 'use client' components
- `lib/supabase/server.ts` — `createServerClient` from `@supabase/ssr` — used in API routes (reads JWT from request cookies)
- `lib/supabase/service.ts` — `createClient` from `@supabase/supabase-js` with `SUPABASE_SERVICE_ROLE_KEY` — used only in `app/api/leads/route.ts`

---

## 8. AI Client Setup

`lib/ai/client.ts` exports:
- `callLLM(systemPrompt, userPrompt)` — wraps `generateText` from `ai` with one automatic retry
- `parseLLMJson<T>(text)` — safe JSON parse, returns null on failure

Model: `anthropic(process.env.ANTHROPIC_MODEL ?? 'claude-haiku-4-5')`

---

## 9. Navigation and Auth Guard

`proxy.ts` (Next.js 16 — renamed from `middleware.ts`) protects: `/idea`, `/questions`, `/research`, `/checkpoint`, `/build`, `/deliverables`.

State routing on sign-in:
```typescript
function getRouteForStatus(status: ProjectStatus): string {
  const routeMap: Record<ProjectStatus, string> = {
    idea_submitted:      '/questions',
    questions_answered:  '/research',
    research_running:    '/research',
    research_complete:   '/checkpoint',
    checkpoint_reviewed: '/build',
    build_running:       '/build',
    build_complete:      '/deliverables',
    stopped:             '/checkpoint',
  };
  return routeMap[status];
}
```

---

## 10. Mock Data Module

`lib/mock-data.ts` is the single source of truth for all mock data. Exports:
- `MOCK_RESEARCH_STEPS: MockStep[]` — 5 steps, durationMs: 3200/4100/2800/5300/2100
- `MOCK_BUILD_STEPS: MockStep[]` — 6 steps, durationMs: 2400/18500/6200/4800/1900/3100
- `MOCK_RESEARCH_OUTPUTS: ResearchOutputs` — pain point signal, competitor map (FreshBooks/Wave/PayPal), GO recommendation
- `MOCK_BUILD_OUTPUTS: BuildOutputs` — research report, recommendation doc, requirements doc, live URL, GitHub link, growth strategy

All exports carry `// MOCK:` comments pointing to real agent pipeline replacements.

---

## Module Boundaries

| Engineer | Files |
|----------|-------|
| backend-1 | `types/index.ts`, `lib/**`, `app/api/**`, `proxy.ts`, `.env.example`, `README.md`, `next.config.ts` |
| frontend-1 | `app/layout.tsx`, `app/*/page.tsx`, `components/**` |
