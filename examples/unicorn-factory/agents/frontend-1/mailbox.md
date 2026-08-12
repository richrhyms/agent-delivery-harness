---
task-id: 2026-06-25-unicorn-factory-mvp-c3f2
agent: frontend-1
role: Frontend Engineer
project: unicorn-factory
project-config: ~/.claude/orchestration/projects/unicorn-factory.md
pm-approved: true
pm-approved-at: 2026-06-25T18:05:00Z
assigned-at: 2026-06-25T18:00:00Z
gate: 5
---

## Task

Implement all 8 screen page components, all shared UI components, the root layout, and the feature components for the Unicorn Factory MVP. The backend scaffold, all API routes, library modules (Supabase clients, AI client, state machine, mock data), TypeScript types, middleware/proxy auth guard, `.env.example`, and `README.md` are already implemented by backend-1 in the project at `~/projects/unicorn-factory/`. Your job is to build all client-facing UI on top of that foundation.

Do NOT modify any API routes, library modules under `lib/`, `types/index.ts`, `.env.example`, `README.md`, `next.config.ts`, or any middleware/proxy file. Your scope is `app/layout.tsx`, all `app/*/page.tsx` files, and all `components/**` files.

## Critical Backend Notes (Read Before Coding)

The backend-1 implementation included two breaking-change deviations from the architecture doc. You must account for both:

1. **Next.js 16 — middleware renamed to `proxy.ts`:** The installed version is Next.js 16.2.9. The auth guard lives in `proxy.ts` (not `middleware.ts`) and exports a `proxy` function (not `middleware`). Do not create a `middleware.ts` — it would conflict. Your page components do not need to worry about this; the proxy handles route protection transparently.

2. **AI SDK v7 — `maxTokens` renamed to `maxOutputTokens`:** `ai@7.0.2` is installed. This only affects `lib/ai/client.ts` (already handled by backend-1). No impact on your UI work, but note it for context.

3. **No `tailwind.config.ts` in Next.js 16 + Tailwind v4:** Tailwind v4 removes `tailwind.config.ts`. Configuration is done via CSS (in `app/globals.css`). Do not create a `tailwind.config.ts`. Apply Tailwind classes directly via `className` in components as normal.

4. **`lib/supabase/service.ts` uses a function export:** `getServiceSupabase()` is exported as a function, not a top-level constant. You will not import from `service.ts` — it is used only by the leads API route — but be aware of this if you read the file for context.

## Input Files

- `~/.claude/orchestration/active/2026-06-25-unicorn-factory-mvp-c3f2/architecture.md` — authoritative reference: component tree with props interfaces (Section 5), navigation and auth guard (Section 9), state routing on sign-in (Section 9), module boundaries (Module Boundaries table)
- `~/.claude/orchestration/active/2026-06-25-unicorn-factory-mvp-c3f2/spec.md` — screen-by-screen UX detail (Section 1), API contracts (Section 4), mock data definitions (Section 6)
- `~/projects/unicorn-factory/` — the actual codebase; read existing files (types/index.ts, lib/mock-data.ts, etc.) before writing components to ensure your code matches the existing types exactly

## Target Directory

`~/projects/unicorn-factory/`

Do NOT create any git commits.

## Constraints

- All components must be TypeScript — no `any` types anywhere
- All styling must use Tailwind CSS utility classes — no CSS modules, no inline `style` objects
- No dead code (no unused imports, no commented-out blocks other than `// MOCK:` passthrough comments that may exist in imports)
- Do NOT install any new npm packages (react-markdown is already installed; no additional dependencies allowed)
- Do NOT modify any file outside `app/layout.tsx`, `app/*/page.tsx`, and `components/**`
- Do NOT create git commits
- All page components must be `'use client'` (they use browser APIs, Supabase browser client, and React state)
- SessionStorage key `uf_project_id` must be used consistently across all pages for projectId persistence
- The `ProgressTracker` must use actual `durationMs` values from mock data — do not shorten them

## Acceptance Criteria

When writing gate-5.md, verify each criterion:

1. [ ] `app/layout.tsx` — complete root layout with Inter font, title, and base Tailwind classes
2. [ ] All 7 `components/ui/` components present and correctly typed (`Button`, `Card`, `Input`, `Textarea`, `Badge`, `Spinner`, `ErrorBanner`)
3. [ ] `components/ProgressTracker.tsx` — animates steps sequentially using actual `durationMs` values; calls `onComplete` after last step
4. [ ] `components/CompetitorTable.tsx` — renders Competitor[] as a styled table
5. [ ] `components/DeliverableCard.tsx` — handles both `markdown` and `link` types
6. [ ] `components/MarkdownRenderer.tsx` — uses react-markdown; correct fallback styling if @tailwindcss/typography absent
7. [ ] `app/page.tsx` — email capture calls `/api/leads`; shows success/error; "Get Started" navigates to `/auth`
8. [ ] `app/auth/page.tsx` — sign-up and sign-in tab flows work with Supabase; sign-in redirects based on project status; on-mount check for existing session
9. [ ] `app/idea/page.tsx` — calls `/api/projects`; handles accept (navigate to /questions) and decline (show error); sessionStorage set
10. [ ] `app/questions/page.tsx` — fetches LLM questions from `/api/projects/[id]/questions`; collects answers; calls submit-answers; navigates to /research
11. [ ] `app/research/page.tsx` — calls research start on mount; uses ProgressTracker with MOCK_RESEARCH_STEPS; calls research complete in onComplete; navigates to /checkpoint
12. [ ] `app/checkpoint/page.tsx` — fetches project data; displays pain point, competitor table, recommendation; handles proceed (→ /build) and stop (→ stopped state); handles stopped status on load
13. [ ] `app/build/page.tsx` — calls build start on mount; uses ProgressTracker with MOCK_BUILD_STEPS; calls build complete in onComplete; navigates to /deliverables
14. [ ] `app/deliverables/page.tsx` — fetches project data; renders all 6 DeliverableCards with correct type assignments
15. [ ] `npx tsc --noEmit` completes with zero TypeScript errors — verify before writing gate file
16. [ ] No `any` types anywhere in implemented files
17. [ ] SessionStorage key `uf_project_id` used consistently on all pages that need projectId

## Output Gate File

Write `~/.claude/orchestration/active/2026-06-25-unicorn-factory-mvp-c3f2/gates/gate-5.md` upon completion.
