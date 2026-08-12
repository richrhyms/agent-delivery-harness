---
task-id: 2026-06-25-unicorn-factory-mvp-c3f2
gate: 4
label: Backend Implementation — backend-1
written-by: backend-1
status: approved
approved-at: 2026-06-25T17:45:00Z
---

## What Was Done

Scaffolded the complete Unicorn Factory MVP backend layer as a greenfield Next.js 16 (App Router, TypeScript, Tailwind, @/ alias) project. Implemented all library modules (types, state machine, three Supabase clients, AI client with retry, mock data), all 10 API routes with auth guards and state machine enforcement, the auth proxy (proxy.ts — Next.js 16 renamed middleware.ts), page stubs for all 8 screens, .env.example, and README with full setup + Extending to Production section. Build passes: `tsc --noEmit` zero errors, `next build` zero errors.

## Deliverable

PR: https://github.com/<org>/unicorn-factory/pull/1
Branch: orchestration/2026-06-25-unicorn-factory-mvp-c3f2/backend-1

## Acceptance Criteria Met

- [x] AC-1: Next.js 14+ App Router project exists at `~/projects/unicorn-factory/` with TypeScript, Tailwind, and `@/` alias configured
- [x] AC-2: All 5 npm packages installed: `@supabase/supabase-js`, `@supabase/ssr`, `ai`, `@ai-sdk/anthropic`, `react-markdown`
- [x] AC-3: `types/index.ts` present with all 30+ interfaces — no `any`
- [x] AC-4: `lib/state-machine.ts` exports `STATE_TRANSITIONS`, `TERMINAL_STATES`, `assertProjectStatus`
- [x] AC-5: `lib/supabase/client.ts`, `server.ts`, `service.ts` all present and match architecture spec
- [x] AC-6: `lib/ai/client.ts` exports `callLLM` and `parseLLMJson` with retry logic and env var model override
- [x] AC-7: `lib/mock-data.ts` present with all 11 exports and all `// MOCK:` comments
- [x] AC-8: `proxy.ts` present (Next.js 16 convention — renamed from `middleware.ts`), protects all 6 routes, redirects to `/auth`
- [x] AC-9: All 10 API routes implemented with correct auth, state guards, and `// MOCK:` labels where applicable
- [x] AC-10: LLM Call 1 system prompt matches `spec.md` Section 5 exactly
- [x] AC-11: LLM Call 2 system prompt matches `spec.md` Section 5 exactly
- [x] AC-12: `.env.example` present with all required env vars and security notes
- [x] AC-13: `README.md` present with setup instructions and "Extending to Production" section
- [x] AC-14: `npm run build` completes with zero TypeScript errors — verified
- [x] AC-15: No hardcoded credentials in any file
- [x] AC-16: No `any` types anywhere in the codebase

## Implementation Notes

**Next.js 16 breaking change — middleware renamed to proxy:**
The scaffolded project uses Next.js 16.2.9 (latest at implementation time). Next.js 16 deprecated `middleware.ts` in favour of `proxy.ts` with an exported function named `proxy` (not `middleware`). The auth guard is in `proxy.ts`. Frontend-1 should be aware of this when reading architecture.md which references `middleware.ts`.

**AI SDK v7 — maxTokens renamed to maxOutputTokens:**
`ai@7.0.2` was installed. In v7, the `maxTokens` parameter to `generateText` was renamed to `maxOutputTokens`. `lib/ai/client.ts` uses `maxOutputTokens: 512`.

**Service client lazy initialisation:**
`lib/supabase/service.ts` exports `getServiceSupabase()` (function) rather than a top-level `serviceSupabase` constant, to avoid module-level evaluation of env vars during Next.js build static analysis (which would fail without credentials).

**No tailwind.config.ts in Next.js 16 + Tailwind v4:**
Tailwind v4 does not use a `tailwind.config.ts` file — configuration is done via CSS. The scaffold correctly omits this file. Frontend-1 does not need to create one.

## Next Phase (if approved)

G-5: Frontend Engineer (frontend-1) implements all 8 screen page components, shared UI components (Button, Card, Input, Textarea, Badge, Spinner, ErrorBanner), ProgressTracker, CompetitorTable, DeliverableCard, MarkdownRenderer, and the root layout — building on top of the API layer and library modules produced in this gate.

---
Type `/orch-approve` to confirm and advance, or `/orch-approve reject <feedback>` to request revisions.
