# Orchestration Project Config

This file provides project-level defaults for the orchestration system.
The `/orch` skill and CTO agent read this on every invocation.

---

## Agent Roster

| Role | Agent File | Max Parallel Instances |
|------|------------|------------------------|
| Spec Specialist | `~/.claude/agents/orchestration/spec-specialist.md` | 1 |
| Architect | `~/.claude/agents/orchestration/architect.md` | 1 |
| Brand Agent | `~/.claude/agents/orchestration/brand-agent.md` | 1 |
| UI/UX Engineer | `~/.claude/agents/orchestration/uiux-engineer.md` | 1 (spec pass) + 1 (design-review pass) |
| Backend Engineer | `~/.claude/agents/orchestration/backend-engineer.md` | **N** (backend-1..backend-N) |
| Frontend Engineer | `~/.claude/agents/orchestration/frontend-engineer.md` | **N** (frontend-1..frontend-N) |
| Integration Engineer | `~/.claude/agents/orchestration/integration-engineer.md` | 1 |
| Code Reviewer (static QA) | `~/.claude/agents/orchestration/code-reviewer.md` | **N** (code-reviewer-1..N + seam pass) |
| E2E Verifier (execution QA) | `~/.claude/agents/orchestration/e2e-verifier.md` | 1 |
| DevOps Engineer | `~/.claude/agents/orchestration/devops-engineer.md` | 1 |
| UAT Engineer | `~/.claude/agents/orchestration/uat-engineer.md` | 1 |
| PM | `~/.claude/agents/orchestration/pm.md` | 1 |
| CTO | `~/.claude/agents/orchestration/cto.md` | 1 |

**Engineer scaling (N):** Backend and Frontend are no longer capped at 2. The CTO sizes the number of
parallel engineer instances to the design's module decomposition — one instance per non-overlapping
scope lane the Architect defines. The PM verifies zero scope overlap across all N before any run. Prefer
the smallest N that keeps lanes truly independent; more instances only help when the work genuinely
parallelizes without shared-file contention.

**Specialist agents** (UI/UX, Brand, UAT) participate in specific phases — see the gate flow in
`README.md` (Design phase and the post-DevOps UAT phase). They are opt-in per plan: the CTO includes
them when the work is user-facing (Brand + UI/UX) and always for a standard delivery's UAT close.

---

## Gate Labels

| Gate | Default Label |
|------|---------------|
| 0 | Understanding Confirmation |
| 1 | Plan Approval |
| 2 | Spec Approval |
| 3 | Design Approval (Architect gate — present in standard flow, omitted in fast-track) |
| 4+ | Assigned dynamically by CTO in plan.md |

Common dynamically-assigned labels (standard user-facing delivery): **Brand**, **UX Design**,
**UX Design Review** (human gate — the product owner approves the proposed end-to-end journey/design via
a published visual link, `ux-review.html`, BEFORE any implementation), Implementation (Backend/Frontend,
N lanes), **Integration** (merge done lanes → one integration branch, re-verify green), **Code Review**
(static QA, scalable to N) + **Design QA** (UI/UX vs approved design), **E2E Verification** (execution QA
— Playwright click-through; **optional**, gated after Code Review), Deployment, **UAT** (post-deployment
user acceptance + learning loop).

**QA is split** into static (**Code Reviewer**, N-scalable) and execution (**E2E Verifier**). They run on
the **integration branch**, not individual PRs. The static→E2E transition is a gate: the operator may
**skip E2E** (recorded, with a reason) — but E2E is the authoritative pass and the default is to run it.

**Branch lifecycle:** lanes (`backend-1..N`/`frontend-1..N`) keep their individual branches + PRs →
Integration Engineer merges them into `integration/<task-id>` → QA + DevOps + UAT all run on that branch
→ after UAT ACCEPTED, the Integration Engineer promotes `integration/<task-id>` → `main` (PR) and only
then retires the lane branches.

Phase placement: Brand + UX Design + UX Design Review in the design phase (before implementation);
Integration + Code Review + Design QA + E2E after implementation; DevOps then UAT last.

---

## Runtime Paths

| Purpose | Path |
|---------|------|
| Active tasks | `~/.claude/orchestration/active/` |
| Archived tasks | `~/.claude/orchestration/archive/` |
| Protocol spec | `~/.claude/orchestration/README.md` |
| Agent definitions | `~/.claude/agents/orchestration/` |

---

## Notification Default

All gate outputs are written to their gate file **and** printed to the Claude Code session
so the user sees them inline. The user then types `/orch-approve` or provides corrections in chat.

Project-specific config (repos, cloud account, deploy method, auth, conventions) lives in:
  `~/.claude/orchestration/projects/<slug>.md`

Run `/orch-setup` to create or update a project config. Run `/orch-setup <project-name>` to target a specific project.
