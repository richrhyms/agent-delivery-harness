# Harness Service — Increment 0: Walking Skeleton (harness input)

> **How to use:** in the new `harness-service` repo, run `/orch ./docs/increment-0-brief.md`.
> **Read `harness-service-brief.md` (the north-star) for full context.** This is the FIRST of several
> coordinated increments — build *only* what's below.
>
> **States goal / scope / constraints — not implementation.** File layout, exact endpoints, and library
> specifics are for the Spec → Architect gates.

---

## Goal

Prove the **riskiest, most novel loop end-to-end, deployed** — before any breadth is built. Deliver a
thin **walking skeleton** of the Harness Service that:

**accepts a job over HTTP → a worker runs one agent inside a Fly Machine (microVM) → writes a gate and
suspends → a human approves over HTTP → resumes → completes — all running on Fly.io, state in Postgres,
with zero local-filesystem runtime dependency.**

This is a vertical slice through *every* architectural layer (API → state → queue/worker → `AgentRunner`
→ Fly-Machine sandbox → deploy), but as thin as possible in each. It is **not** a useful build engine
yet — it exists to de-risk the runtime and prove cloud-deployability.

## Why this first

The CLI harness only runs locally inside Claude Code. The one thing that must be proven before investing
in breadth is that the **same gated loop can run headless, suspend/resume via API, execute an agent in an
isolated microVM, and do it on a deployed host.** If that works, the rest is incremental.

---

## Scope — build ONLY this

### The loop
1. **`POST /jobs`** — create a job from a trivial JSON body (e.g. `{ "input": "..." }`). Persist it;
   enqueue one phase. Return `{ job_id }`.
2. A **worker** (separate process) consumes the queue, and for the job's phase invokes the **`AgentRunner`**.
3. **`AgentRunner` (self-hosted Claude Agent SDK impl)** spawns a **Fly Machine (Firecracker microVM)** via
   the Machines API, runs a **trivial agent** inside it (e.g. an Agent SDK agent whose task is "write a
   short output / a file from the job input"), captures the agent's output, then **destroys the Machine**.
4. The worker records the phase output, writes a **gate row = `pending`**, sets the job to
   **`awaiting_gate`**, and **releases** (nothing left running).
5. **`GET /jobs/{id}`** reflects the current status + the pending gate + its output.
6. **`POST /jobs/{id}/gates/{n}/approve`** → the job **resumes** and **completes** (a single phase is
   enough; a second trivial phase is optional to show advancement). **`.../reject`** → the phase re-runs.

### Persistence & queue
- **Postgres** (Neon): minimal `job`, `gate`, `phase`, `event` tables — enough to hold the state machine.
- **Postgres-backed queue** (e.g. `pg-boss` or `SELECT … FOR UPDATE SKIP LOCKED`).
- **Durability:** all state in Postgres — killing and restarting the worker mid-flight must **resume**
  from the DB, not lose the job.

### Deploy (the whole point)
- **Deploy to Fly.io:** API and worker as **Fly apps** (containers); the phase sandbox as a **Fly Machine**
  spawned per phase; **Neon** Postgres. Configuration **entirely via environment variables**.
- A minimal **API key** guards the endpoints.

## Explicitly OUT of scope for Increment 0 (later increments)

- The **plan-driven orchestrator** and the **real ported agents** — use one or two **hardcoded trivial
  phases** and a **placeholder agent**. (Real CTO planning + real agents = Increment 1.)
- Parallel lanes, Integration, Code Review/E2E, Brand/UX/UX-Design-Review, DevOps-of-the-built-product,
  UAT, Learning Loop, Promote.
- Outbound **webhooks**, the platform boundary, `required_role` routing.
- **git-per-build** repos, Supabase/Vercel **provisioning**, the **secret vault**, object storage,
  multi-tenancy, egress allowlists, HMAC signing. (Keep secrets as plain Fly secrets/env for now.)

Building any of the above in this increment is out of scope — flag it and stop.

## Constraints (inherit from the north-star brief)

- **Python / FastAPI**; **Postgres**; self-hosted **Claude Agent SDK** behind the **`AgentRunner`** seam;
  **Fly Machine** sandbox; **Postgres-backed queue**; **containerized**; **12-factor** (env-only config,
  **no local-filesystem runtime dependency**, stateless worker).
- Adapt the **ai-writer FastAPI skeleton + scaffolding** (routers/prefix/lifespan/Sentry, Docker) — adapt
  patterns, don't copy business logic.
- Keep the `AgentRunner` and queue behind interfaces so their implementations can be swapped later.

## Acceptance criteria (Increment 0 "done")

1. Service is **deployed on Fly.io** (API + worker as Fly apps, Neon Postgres) and reachable over HTTPS.
2. `POST /jobs` creates a job; the worker picks it up automatically.
3. The phase runs a Claude Agent SDK agent **inside a Fly Machine that is spawned and destroyed per phase**
   — evidenced in logs/records (Machine id, lifecycle, agent output captured).
4. The job **suspends** at a gate (`awaiting_gate`); `GET /jobs/{id}` shows it with the phase output.
5. `POST …/approve` **resumes → completes**; `POST …/reject` re-runs the phase.
6. **Durability proven:** kill the worker mid-run, restart it, and the job still resumes from Postgres.
7. Config is **entirely env vars**; there is **no local-filesystem runtime dependency**; the exact same
   image runs deployed. **Localhost-only does not pass.**
8. Endpoints require the API key.

## Open questions for the CTO / Architect

- **Fly Machines integration:** how the worker authenticates to and drives the Machines API; the sandbox
  **image** the Machine boots; and how the **Agent SDK agent runs inside it** (recommended: the Machine
  boots a small "phase-runner" image that invokes the SDK agent and returns the result — keep it simple).
- **Queue** choice (`pg-boss` vs hand-rolled `SKIP LOCKED`) — pick the simplest that gives at-least-once
  + retry.
- Minimal **schema** for `job/gate/phase/event` sufficient for this loop (extended in later increments).

## First steps for the CTO

1. Gate 0 — restate understanding against the Goal + "build ONLY this" scope.
2. Plan a **small** gate sequence to build this (it is a small service: Spec → Architect → 1–2 Impl lanes
   → **DevOps deploy to Fly.io**). Include the deploy gate — Increment 0 is not done until it runs on Fly.
3. Proceed gate by gate; treat the north-star brief's locked decisions as fixed constraints.
