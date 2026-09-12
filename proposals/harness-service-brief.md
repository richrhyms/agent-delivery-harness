# Harness Service — Phase 1 Build Brief (harness input)

> **How to use:** create the new service repo (suggested name `harness-service`), then run
> `/orch ./docs/harness-service-brief.md` (or point `/orch` at this file / a GitHub issue built from it).
> The harness will normalize this into its own `brief.md`. This is a **greenfield** build.
>
> **This brief states goal / scope / constraints / decisions — not implementation.** The exact file
> layout, endpoint signatures, and library specifics are for the Spec → Architect gates to define.

---

## Goal

Build **Phase 1 of the Harness Service**: turn the current **CLI, human-gated multi-agent delivery
harness** into a **self-hosted HTTP service** that Unicorn Factory (the platform) calls to run software
builds — **driven by the same human gates we have today, but over an API instead of `/orch-approve` at a
terminal.**

It is a **generic, plan-driven gated-orchestration engine**: it does not hardcode a gate list; it runs
whatever gate sequence the CTO agent's plan specifies, using the existing harness agents. The full flow
(Spec → Architect → Brand → UX Design Review → Impl(N) → Integration → Code Review → E2E → DevOps → UAT →
Learning Loop → Promote) is therefore supported *by construction*.

## Delivery approach — coordinated increments (not one big build)

This document is the **north-star reference** for Phase 1. The work is delivered as an ordered sequence
of **vertical-slice increments**, each handed to the harness as its own small brief, reviewed, then
followed by the next — de-risking the novel parts first:

0. **Walking skeleton** — FastAPI + Postgres + minimal job/gate API + one dummy phase that runs an agent
   via `AgentRunner` in a Fly Machine, suspends at a gate, resumes on approve, **deployed to Fly.io**.
1. Minimal real flow (plan-driven orchestrator, short real gate sequence, git-branch output).
2. Parallel lanes + Integration + split QA (Code Review + E2E).
3. Design phase + UX Design Review (published link) + webhooks + platform boundary + DevOps/UAT/Promote.
4. Hardening (telemetry, secrets, egress limits, retries, observability).

Each increment must satisfy the deployability requirement below — no increment is "done" on localhost.

## Context (why, and what already exists)

- **The CLI harness** (`agent-delivery-harness`) is Claude-Code-native: subagents, `~/.claude` discovery,
  slash commands, file-based state in `~/.claude/orchestration/active/<task-id>/`, and a human
  `/orch-approve` between every phase. Its **13 agent definitions and its gate protocol are the real IP**
  and must be **reused/ported, not rewritten**.
- **Unicorn Factory** (the platform) refines founder ideas, takes payment, and needs a build engine. ADR-1
  (its `docs/product/architecture.md`) named the harness the engine and sketched a v2 "service / job
  queue" — **this brief builds that.** Decision on record: **build our own engine, self-hosted** (not buy).
- **The ai-writer** (`contently-ai-writer`, Python/FastAPI) is a **learning + reuse reference** for the
  service *skeleton* only (see Reuse Directives). It is a stateless request→respond LLM pipeline; it has
  **no jobs, gates, or human-in-the-loop**, so it does not inform the core of this service.
- **Claude Managed Agents** was evaluated and **rejected** as the substrate (vendor lock-in + unmetered
  managed cost — "another AWS"). We self-host the **Agent SDK** behind a swappable seam instead.

## The core principle

The service never holds a build in memory for hours. **Job state lives in Postgres; a phase run is a
discrete, idempotent task; a gate pause is simply "no next task enqueued"; a human approval (via API)
enqueues the next task.** Durable execution comes from an explicit DB state machine + re-enqueue, not a
heavyweight workflow engine.

---

## Scope — Phase 1 (locked design decisions as requirements)

### 1. Job lifecycle & the human-gate API
- A **job** = one build request. Statuses: `queued`, `active`, `awaiting_gate`, `completed`, `failed`,
  `cancelled`, with a `current_gate` cursor. `awaiting_gate` is the suspended-for-human state. **(D1)**
- API surface (shape, not signatures): `POST /jobs` (body = the brief); `GET /jobs/{id}`;
  `GET /jobs/{id}/gates` and `/gates/{n}`; `POST /jobs/{id}/gates/{n}/approve` and `/reject`;
  `POST /jobs/{id}/cancel`. Approve/reject is the `/orch-approve` equivalent. **(A.1)**
- A pending **gate** exposes: label, `written_by`, summary, acceptance criteria, **typed deliverables
  incl. links** (e.g. the published UX-review URL, PR URLs), a **per-gate `actions[]`** set (e.g.
  `approve | skip-e2e`, `approve | re-scope | decline`), a **`required_role`** for routing, and a
  **version/etag**. **(A.1)**
- **One pending gate at a time**; approve/reject must carry the etag; **idempotent** (guards against
  double-approval/stale-UI). **(D5)**
- **`reject`** loops back to the gate's owning agent to revise → re-writes the same gate. **(D4)**
- **Notifications:** signed **webhooks** (`gate_pending`, `job.status_changed`, `completed`, `failed`,
  `artifact_published`) + `GET /jobs/{id}` polling fallback. **(D2)**
- **Phase-1 approver:** a single authenticated operator actions gates via API; the gate still carries
  `required_role` so the platform can route per-actor later. **(D3)**

### 2. Durable state & persistence (Postgres)
- **Postgres** for all state — relational for the gate state machine, JSONB for flexible payloads; aligns
  with the platform's Supabase/Postgres. **(D6)**
- Entities: **`job` / `gate` / `phase` (agent_run) / `artifact` / `event` / `project`.** **(D7)**
  Replace the file-based state 1:1: `brief.md`→`job.brief`, `gates/gate-N.md`→`gate` rows,
  `agents/<role>/mailbox.md`→`phase.mailbox`, `state.md`→queries, spec/design/reports/`ux-review.html`→
  `artifact`.
- **Artifacts:** small text/JSON inline; **large/published artifacts (incl. the UX-review page) → object
  storage** (S3/R2/Supabase Storage) with a URL + access control. **(D8)**
- **Code & sandbox stay OUT of the DB:** code lives in **git** (lane branches, `integration/<job>`, PRs) —
  the DB references branch names/PR URLs; the sandbox FS is ephemeral. **(D9)**

### 3. Worker, orchestrator & execution (`AgentRunner`)
- **Postgres-backed job queue** (e.g. `pg-boss` / `SELECT … FOR UPDATE SKIP LOCKED`) + explicit DB state
  machine. No new infra, no lock-in. A durable workflow engine (Temporal/Restate/Inngest) is a documented
  "graduate to if complexity demands," behind the same abstraction — **not Phase 1.** **(D10)**
- The **orchestrator is service code** driving discrete `run_phase(job, phase)` tasks; **planning is an
  agent call** (the CTO agent produces the plan/gate sequence), **sequencing is code.** Suspend = no task
  enqueued; resume = approve-API enqueues next. **(D11)**
- **`AgentRunner` seam:** `run(role, mailbox, inputs, sandbox) → { outputs, artifacts, gateDraft,
  telemetry }`. Default impl = **self-hosted Claude Agent SDK** (agent loop runs in a sandbox; model
  chosen from config; streams events; captures outputs → git/artifacts; records **token/cost
  telemetry**). The seam must allow an alternate runner (Managed Agents) later without touching
  orchestration. **(D12)**
- **Parallel lanes:** a parallel phase fans out N `run_phase` tasks; a **join** advances only when all N
  sub-gates are written (mirrors the harness's parallel sub-gates + single approval). **(D13)**
- **Reliability:** queue-level retries; phases idempotent; hard failure → `job.failed` + event; a worker
  crash re-delivers the task and resumes from DB. Suspension is **only at gates, between phases** — an
  agent run (even a long one) completes within its phase; no mid-run freeze/rehydrate. **(D14)**

### 4. Sandbox (what `AgentRunner` executes inside)
- **One ephemeral sandbox per phase run — a Fly Machine (Firecracker microVM) spawned via the Machines
  API**, then destroyed; the agent runs **inside** it, the build repo cloned in, outputs promoted to git.
  This is the concrete `AgentRunner` sandbox for Phase 1; an alternate (VM+Docker, k8s Job, E2B) can swap
  in behind the seam later. **(D15)** Two image variants: a **build image** (git + Node toolchain) and
  an **E2E image** (adds Playwright + browsers; can boot the app + seed test-mode services). **(D19)**
- **Per-build provisioning (ADR-3):** the **git repo/branch in our org is automated**; **Supabase/Vercel
  per-build provisioning is scripted/concierge in Phase 1** (full auto = Phase 2). **(D16)**
- **Secrets:** per-build **scoped, short-lived** tokens (GitHub push, Anthropic model key, deploy tokens)
  from a secret store, **injected at runtime**, never baked into images or leaked into customer
  repos/artifacts, **rotated out at handover** (Model A). **(D17)**
- **Hardening / cost control:** **egress allowlist** (npm, GitHub, Anthropic, Supabase, Vercel), no
  inbound; **hard CPU/mem/time caps**; **ephemeral teardown** → bounded runs + predictable spend. **(D18)**

### 5. Tenancy & the platform boundary
- **Single-tenant** in Phase 1 (Unicorn Factory is the only consumer; jobs scoped internally via
  `project`). Schema must not preclude multi-tenant later. **(D20)**
- **Boundary:** the platform owns the **pre-build business gates** (Commission → Green-Light → Ignition =
  payment/T-0) and customer UX + human routing; **this service owns the build orchestration and its
  gates**, and is **invoked at T-0** (post-payment). Integration = **job API (platform→service) + signed
  webhooks (service→platform).** **(D21)**
- **Gate routing:** the service exposes `required_role`; the platform routes (ops → technical gates;
  founder → UX Design Review + UAT). **(D22)**
- **Auth:** **API key (platform→service) + HMAC-signed webhooks (service→platform)** for Phase 1;
  OAuth/mTLS + per-tenant keys are Phase 2. **(D23)**

---

## Constraints (non-negotiable)

- **Stack:** **Python / FastAPI**, **Postgres**, self-hosted **Claude Agent SDK**, **containers** for the
  sandbox, a **Postgres-backed queue**.
- **No Claude Managed Agents** as the substrate (self-host the Agent SDK behind the `AgentRunner` seam so
  it stays swappable).
- **All gates remain human in Phase 1**, actioned via API — a faithful port of the CLI flow. No gate
  automation.
- **Reuse, don't rewrite** (see Reuse Directives).
- **Cost control is a first-class requirement:** bounded/ephemeral runs, egress allowlist, and per-run
  token/cost **telemetry captured** on every phase.
- **Cloud-deployable, never localhost-only (non-negotiable).** 12-factor discipline: **all configuration
  via environment variables**; **no dependence on the local filesystem** for state or artifacts (Postgres +
  object storage only); **containerized**; **workers stateless and horizontally scalable**. The service
  must run unchanged on a deployed host — a developer's machine is only for local dev, never a runtime
  assumption.

## Deployment (locked)

- **Target platform: Fly.io.** API and workers run as **Fly apps** (containers). The **per-phase sandbox
  (D15) runs as a Fly Machine (Firecracker microVM) spawned via the Machines API**, then destroyed — this
  is the concrete implementation of the `AgentRunner` sandbox for Phase 1.
- **Postgres:** managed — **Neon** (or Supabase, which the platform already uses).
- **Object storage:** **Cloudflare R2** (or Supabase Storage).
- **Portability:** because everything is containers behind the `AgentRunner`/queue seams, this can later
  move to a VM+Docker host, k8s, or an alternate sandbox (E2B) **without changing orchestration** — the
  Fly.io choice is the default, not a lock-in.

## Reuse directives (D24)

- **Adapt from the ai-writer:** the FastAPI skeleton (routers/prefix/lifespan/Sentry), the
  **routes → DTOs → validators → services** layering, the **config-driven role→model mapping**
  (`llm_config.json` → our `agent_config`), and production scaffolding (Docker/compose/Procfile,
  healthchecks, guardrails, settings, logging, pydantic discipline). Adapt patterns — do not copy business
  logic.
- **Reuse from the existing harness (the IP):** the **13 agent definitions** (`agents/*.md`) become the
  Agent SDK agents' **system prompts** (CTO, Spec, Architect, Brand, UI/UX, backend/frontend-N,
  Integration, Code Reviewer, E2E Verifier, DevOps, UAT, PM); the **`protocol.md` gate model** becomes the
  service's orchestration state machine.
- **Build new:** the durable job/gate state machine, queue+worker+orchestrator, `AgentRunner`+sandbox, the
  human-gate API + webhooks, and git/provisioning integration.

## Out of scope — Phase 2 (do NOT build now)

Multi-tenancy; full Supabase/Vercel auto-provisioning; **gate automation** (removing human gates);
a durable workflow engine and/or a Managed-Agents `AgentRunner`; microVM/managed-sandbox hardening;
OAuth/mTLS; scale-out and observability dashboards.

## Acceptance criteria (Phase 1 "done")

1. A build can be submitted via `POST /jobs` (body = a brief) and run **end-to-end through the plan's gate
   flow entirely over the API** — no CLI/terminal interaction.
2. Each phase runs the correct **existing agent** via the self-hosted Agent SDK **in a container**; outputs
   land on a **per-build git branch**; parallel lanes fan-out and join.
3. Every gate **suspends** the job (`awaiting_gate`); `approve` resumes, `reject` revises the same gate;
   `skip-e2e` is honored and recorded; **one-at-a-time + etag** enforced.
4. **Webhooks** fire on `gate_pending` and terminal events; `GET /jobs/{id}` reflects true state.
5. **All state is in Postgres**; killing and restarting the worker **resumes** the job with no loss.
6. Single-tenant **API-key** auth; **HMAC-signed** webhooks; per-phase **token/cost telemetry** recorded;
   sandboxes are **ephemeral, egress-limited, resource-capped**.
7. **Demonstration:** drive one real build (a small project, or a slice of unicorn-factory) from brief →
   gated flow (approving over HTTP) → delivered branch, with the human never leaving the API.
8. **Deployed, not localhost:** the demonstration in (7) runs against the service **deployed on Fly.io**
   (API + workers as Fly apps; the phase sandbox as a Fly Machine), configured entirely via environment
   variables, with **no local-filesystem runtime dependency**. Running only on a developer machine does
   not satisfy this criterion.

## Open questions for the CTO / Architect

- Exact **Agent SDK ↔ sandbox** composition (does the SDK loop run in the container, and how are session
  and filesystem managed per phase).
- **Queue** specifics (`pg-boss` vs hand-rolled `SKIP LOCKED`), and container orchestration for Phase 1
  (plain Docker vs a minimal runner) — keep it minimal.
- The **brief schema** the platform will POST (align with the existing harness `brief.md` and the
  platform's refinement output).
- **Secret store** choice and the per-build token-scoping mechanism.

## First steps for the CTO

1. Gate 0 — restate understanding against the Goal + core principle above.
2. Plan the gates. This is a **standard, user-facing-enough** build (it has an operator console surface and
   a real UX for the gate/job API), so include the **design phase (Brand + UX Design + UX Design Review)**
   for any operator UI, and the full QA → deploy → UAT tail.
3. Proceed gate by gate. Treat the 25 locked decisions above as fixed design constraints; surface any that
   the Architect finds infeasible rather than silently deviating.
