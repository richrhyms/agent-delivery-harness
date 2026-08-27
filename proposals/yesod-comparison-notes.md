# Harness Review Notes — Ideas from Yesod (yesod.work)

> **Status:** REFERENCE / idea capture for the harness-hardening workstream. Not a decision.
> **Captured:** 2026-08-26
> **Source:** yesod.work — a self-hosted, cost-aware, multi-agent "software factory" for *engineering
> teams* (creator: Stephen Barr; commercial arm MeshCrawler). Same category as our
> `agent-delivery-harness`. It sells the **engine**, not a founder-facing studio — so it's a
> design peer to steal from, not a business competitor. Build-vs-buy already decided: **build our own**
> (see unicorn-factory/docs/product/architecture.md ADR-1).
> **Related:** [`qa-hardening.md`](./qa-hardening.md) — several ideas below reinforce that draft.

---

## How Yesod is structured (their "rooms" / pipeline)

Capture → Planning → Dispatch → Runners → Merge/Gates → Delivery. Maps closely onto our
host → CTO/PM → Spec/Architect → Backend/Frontend → QA → DevOps flow. Worth noting where their
mechanisms are sharper than ours.

---

## Ideas worth stealing (ranked by value to us)

### ⭐ 1. Evidence-gated merge — "green alone authorizes the push"
Their merge system is a **deterministic authority**: one exact tested candidate SHA, one terminal
verdict, and **only a passing gate authorizes merge**. Failed attempts don't reopen — they become a
**new fenced attempt** that must re-pass the *complete* gate. Even their AI conflict-repair job **has no
merge authority** — its proposal must re-enter as a fresh attempt and pass every gate.
- **Why it matters to us:** directly attacks our QA's "static review only" gap (see qa-hardening B-track).
  The principle to adopt: **a gate verdict must be backed by executed evidence tied to an exact commit,
  not a reviewer's opinion.** No green, no merge — no exceptions, no "looks fine to me."
- **Steal:** the "fresh attempt must pass the *whole* gate" rule (no partial re-approval of a patched
  candidate) and "repair has no authority" (our QA/fix agents shouldn't be able to self-bless a fix).

### ⭐ 2. Bounded runs the agent "can't talk its way out of"
Runners enforce **hard time / token / retry bounds** that no agent can override, and execute in an
**isolated worktree**, one task at a time. Output + evidence + cost land in a **durable record whether
the run succeeds or fails.**
- **Why it matters:** our gates assume good-faith completion; we lack explicit non-negotiable bounds and
  a uniform "record even on failure" rule.
- **Steal:** per-agent hard budgets (wall-clock, tokens, retry count) declared outside the agent's
  control; **persist evidence on failure too** (not just on success) so a failed gate is debuggable.

### ⭐ 3. Cost-aware dispatch as an explicit, *recorded* decision
Their dispatcher selects `{model, harness, runner/VM, budget}` from: complexity estimate (informs, does
not dictate), capability requirements, available resources, **budget limits**, and **pins**
(user/model constraints). Every selection writes a **"routing reason"** to the record. A **pin is a
constraint, not a promise of an undocumented fallback** — no silent downgrade.
- **Why it matters:** our opus-design / sonnet-execution split is a *static convention*. Theirs is a
  per-task, logged decision with a rationale.
- **Steal:** (a) record a **routing reason** whenever we assign a model to an agent/task, so model
  choice is auditable (this is exactly the ammunition ADR-8's estimator + the QA model-bias track want);
  (b) **no silent fallback** — if a pinned model isn't available, fail loudly rather than quietly
  downgrading quality.

### 4. Atomic work-claiming (parallel-safety)
"The claim is atomic. Two runners should not discover the same work and both believe they own it."
- **Why it matters:** our parallel safety is by **module ownership** (static partition). Fine for now,
  but if we ever move to a queue, we need atomic claim to avoid double-execution.
- **Steal:** keep in back pocket for when harness parallelism goes dynamic (ADR-1 v2 job-queue path).

### 5. Readiness validation before dispatch
Before routing, they check: lifecycle state is executable, plan is current, **dependencies satisfied**,
repo ready, runner capacity, retry limits, no duplicate claim.
- **Why it matters:** a cheap pre-flight that prevents wasted/incoherent runs.
- **Steal:** a lightweight **pre-gate readiness check** (deps met? spec current? prior gate green?)
  before spinning up an execution agent.

### 6. Complexity estimate as a first-class signal ("Beads": 3–10 node task trees)
Planning decomposes work into task trees of ~3–10 nodes with **acceptance criteria**, and emits a
**complexity estimate** that feeds routing.
- **Why it matters:** this is *literally* our unicorn-factory estimator input (ADR-8 / Open Decision #5).
  Their harness produces the complexity signal the business layer needs.
- **Steal:** have our planning/spec stage emit a **structured complexity estimate + acceptance criteria
  per work-node** — reused by (a) model routing and (b) the platform's cost estimator. One artifact,
  two consumers.

### 7. Durable, queryable record of everything
Requests, decisions, gates, failures, **costs**, outcomes — all persisted with provenance; original
request stays attached to the deliverable through delivery.
- **Why it matters:** feeds observability, est-vs-actual cost tracking (a day-1 metric we flagged), and
  the customer-facing evidence/Reality Map.
- **Steal:** ensure every gate writes a structured record (verdict, evidence ref, cost, model, reason),
  not just prose in a markdown gate file.

---

## Where we're already fine / ahead (don't copy)
- **Human approval gates** — our gate-driven, user-approved flow is a strength; theirs is more autonomous.
- **Business/founder layer** — entirely absent from Yesod; that's our moat, not a harness concern.
- **Isolation tech** — they mention "isolated worktree / local VMs / Lambda microVMs" but don't commit;
  our per-build isolation (repo + fresh Supabase/Vercel, unicorn ADR-3) is more concrete for our use.

---

## Net takeaway for the harness review
Three themes converge with our existing [`qa-hardening.md`](./qa-hardening.md) and should anchor the
review: **(1) evidence-gated merge — executed proof tied to an exact commit authorizes advancement, an
opinion never does; (2) hard, agent-proof budgets with evidence persisted even on failure; (3) model
routing as a recorded decision with a reason and no silent fallback.** The complexity-estimate + acceptance-
criteria artifact (#6) is the one piece that also feeds the *business* side (unicorn ADR-8) — highest
leverage, build once.

**Open the actual station details later:** yesod.work/book and the /how-it-works/* pages promise a
"full station guide" in a forthcoming edition — re-check for concrete gate/isolation mechanics before we
finalize harness changes.

---

## Adopt an empirical posture — capture our own runs (highest-leverage habit)

Yesod publicly frames the factory as an *experiment* (they cite "2,100 autonomous agent runs across 20
models, 2.8B tokens"). Caveat: those are **activity** metrics (tokens are cheap); the metrics that
actually matter to us are **quality-accepted rate, est-vs-actual cost delta, on-time %.** Lesson to
adopt regardless: treat our harness as *measured*, not *assumed*.

**Action (from build #1): instrument the harness to capture per-run telemetry —**
`{ build_id, task/node, complexity_estimate, model, tokens, cost, wall_clock, gate_verdict, accepted? }`
persisted to the durable record (even on failure). This single habit turns two of our open questions
into a dataset instead of a guess:
- **est-vs-actual cost delta** — already our day-1 risk (unicorn-factory discovery.md §7).
- **complexity-estimation accuracy** — directly tightens ADR-8's estimator confidence band over time.

---

## Open questions checklist (from Yesod's research agenda)

Their 15 research questions ≈ our planning agenda restated. Tagged by our current stance so we know
what's settled vs. what a harness review must actually resolve.

**✅ Already positioned (validate, don't re-open):**
- Planning/execution cost-time-quality tradeoff → our opus-design / sonnet-execution tiering.
- Expensive models plan & supervise cheaper execution → the two-tier split (core bet).
- Right set of focused agent roles → CTO/PM/Spec/Architect/Backend×2/Frontend×2/QA/DevOps roster.
- Persistent vs ephemeral agents → persistent host, ephemeral execution agents.
- Dispatch accounts for cost **and reliability** → routing-reason + no-silent-fallback (⭐3 above) +
  QA model-bias track (qa-hardening.md).

**🔶 Open — a harness review should resolve (high value to our economics/promise):**
- **How accurately can a factory estimate task complexity?** → the estimator accuracy question; feeds
  ADR-8 confidence band. *Answer empirically via per-run telemetry above.*
- **Can the factory inspect its own history and learn over time?** → we have **no** learning loop today.
  Real gap; the telemetry record is the precondition for it.
- **How much agent-to-agent communication is necessary / how decoupled can agents be?** → we have a
  *position* (schema'd handoffs + module-ownership decoupling) but haven't measured it.
- **Can dispatch account for both cost and reliability?** → partially positioned; needs a reliability
  signal per model, not just a cost tier.
- **How should the factory respond to changing prices / batch discounts?** → not considered; affects
  margin at volume. Park until scale, but note it.
- **What configuration produces the best work?** → the meta-question; only answerable once telemetry
  exists to compare configs.

**⚪ Not relevant to our business now (Yesod infra research — skip unless a customer needs it):**
- Run locally / air-gapped.
- Rich playground of compute + test environments.
- How the programming environment prepares knowledge for future agents.

**🎯 Already our product thesis (not an open question for us):**
- **Human role moving from supervising execution → setting creative direction.** Yesod frames this as
  research; for Unicorn Factory it *is* the product (founder sets direction, factory executes, human
  approval gate stays). No action — just confirmation we're aimed right.

---

### Bottom line for the harness review
Place confidence correctly: **more** confident the *architecture* is right (independent peer
convergence at scale); **not** more confident our *delivery quality* is proven (still unearned — earn it
via real founder acceptances). The cheap, high-leverage move is the **per-run telemetry**; everything
else in the 🔶 list becomes answerable once we're capturing our own runs.
