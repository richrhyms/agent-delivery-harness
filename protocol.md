# Orchestration Protocol Spec

This document defines all file schemas used by the multi-agent orchestration system.
Every agent reads and writes files according to these schemas. Do not deviate.

---

## Directory Layout

### Global

```
~/.claude/orchestration/
├── config.md              ← system config (agent roster, gate labels, paths)
├── README.md              ← this file (protocol spec and schemas)
├── projects/              ← per-project configs (one file per project, created by /setup)
│   ├── acme.md
│   └── beta-app.md
├── active/                ← in-progress tasks
└── archive/               ← completed tasks
```

### Per Task

```
~/.claude/orchestration/active/<task-id>/
├── brief.md              ← Normalized input (written by /orch)
├── plan.md               ← Formal execution plan (written by CTO, signed by PM)
├── spec.md               ← Project spec (written by Spec Specialist)
├── design.md             ← Technical design: API contracts, data models, scope assignments (written by Architect)
├── state.md              ← CTO navigation index (fast-path startup; written/updated by CTO only)
├── gates/
│   ├── gate-0.md         ← CTO understanding confirmation (pending user approval)
│   ├── gate-1.md         ← Plan approval (pending user approval)
│   ├── gate-2.md         ← Spec approval (pending user approval)
│   └── gate-N.md         ← Per-phase deliverable gate
└── agents/
    ├── spec/mailbox.md
    ├── backend-1/mailbox.md
    ├── backend-2/mailbox.md
    ├── frontend-1/mailbox.md
    ├── frontend-2/mailbox.md
    ├── qa/mailbox.md
    └── devops/mailbox.md
```

Archive: `~/.claude/orchestration/archive/<task-id>/` — completed tasks moved here.

---

## Task ID Format

`<YYYY-MM-DD>-<slug>-<4-char-hex>` where slug is 3-5 words from the brief, hyphenated, and the hex suffix prevents collisions.

Example: `2026-06-11-user-auth-refactor-a3f1`

---

## Parallel Gate Naming

When multiple agents run in the same phase, they use sub-gate lettering to avoid file collisions:

| Phase structure | Gate file names |
|-----------------|-----------------|
| Single agent | `gate-3.md` |
| Two agents in parallel | `gate-3a.md`, `gate-3b.md` |
| Three agents in parallel | `gate-3a.md`, `gate-3b.md`, `gate-3c.md` |

Sub-gate assignments MUST be pre-declared in `plan.md` before the phase begins. The CTO presents all sub-gates for the phase together and the user approves the whole phase with a single `/orch-approve`.

---

## File Schemas

### `project config file`

Path: `~/.claude/orchestration/projects/<slug>.md`

One file per project. Created and updated by `/orch-setup`. The slug is a short lowercase-hyphenated identifier (e.g. `acme`, `beta-app`).

```markdown
---
project: <slug>
display-name: <Human Name>
configured: true
repos:
  - owner/repo
  - owner/repo2
---

## Platform & Stack
- platform: <Salesforce | Node.js | Python | Java | Go | ...>
- tech-stack: <comma-separated list>

## Cloud / Infrastructure
- cloud-provider: <AWS | GCP | Azure | none>
- account-id: <12-digit account or "unknown">
- region: <e.g. eu-west-1>
- aws-profile: <profile name or "unknown">
- deploy-method: <Terraform | CDK | Serverless Framework | sf deploy | none>

## Runtime Environments
- dev-env: <org alias | ECS cluster | k8s namespace>
- staging-env: <value or "none">
- prod-env: <value or "none" / "manual-only">

## Auth Approach
- deploy-auth: <OIDC via GitHub Actions | saml2aws | IAM keys | sf org auth>

## Health Check
- health-check-cmd: <command or "unknown">

## Conventions
- investigation-doc-pattern: <e.g. docs/GH-{number}-investigation-claude.md>
- prompt-output-file: <e.g. docs/super-ai/prompt-ai-claude.md>
```

The `repos:` list is used by `/orch` to detect which project a task belongs to when given a GH input. Include every repo that belongs to the project.

---

### `brief.md`

Written by `/orch`. The normalized input that the CTO receives.

```markdown
---
task-id: <task-id>
project: <slug>
created: <ISO date>
input-type: filepath | gh-url | gh-shorthand | direct
source: <original input value>
status: pending-gate-0
mode: plan-only | fast-track | <omit for full standard execution>
---

## Goal
[1-3 sentence statement of what needs to be done]

## Known Context
[Relevant background: repo, issue links, constraints, prior work]

## Constraints
[Non-negotiable boundaries: tech stack, deadline, scope limits]

## Open Questions
[Things not yet known that the CTO should resolve or flag]
```

---

### `design.md`

Written by the Architect after spec.md is approved. The authoritative source for how implementation agents divide and implement the work. Engineers must not deviate from scope assignments or API contracts defined here without raising a revision.

```markdown
---
task-id: <task-id>
written-by: architect
status: draft
---

## Architecture Overview
[1-3 sentences: the technical approach and key decisions]

## API Contracts
### <METHOD /path>
- **Request body:** `{ field: type }`
- **Response (success):** `{ field: type }` — HTTP <status>
- **Response (error):** `{ error: string }` — HTTP <status>
- **Owner:** backend-1 | backend-2

## Data Models
### <ModelName>
| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|

## Module Boundaries
| File / Module | Responsibility | Owner |
|---------------|---------------|-------|

## Shared Interfaces
[Agreed types/enums/constants with their actual definitions]

## Scope Assignment Summary
| Engineer | Components | FRs Covered | ACs Covered |
|----------|-----------|-------------|-------------|

## Open Technical Questions
[Questions that must be resolved before implementation — empty if none]
```

Note: `status: draft` is permanent for design artifacts — the file is not updated to `approved`. Approval of the Architect's gate file (`gate-3.md status: approved`) is the signal that design.md is ratified. Agents that read design.md should treat it as authoritative once the Architect gate is approved.

---

### `state.md`

Written and maintained exclusively by the CTO. A derived navigation index — never the source of truth for gate decisions, but always kept consistent with the gate files. Enables the CTO startup fast path: instead of re-reading all gate files on every invocation, the CTO reads state.md to know exactly where it is and reads only the files needed for the next action.

```markdown
---
task-id: <task-id>
current-gate: <N>
status: pending-gate-N | active | complete
last-updated: <ISO timestamp>
---

## Gate Index
| Gate | Label | Status | Written-by |
|------|-------|--------|------------|
| 0 | Understanding Confirmation | approved | cto |
| 1 | Plan Approval | approved | cto |
| 2 | Spec Approval | pending | spec-specialist |

## Active Agents
| Role | Mailbox status | Gate |
|------|---------------|------|
| spec | complete | 2 |

## Last Action
gate-2 written by spec-specialist (pending user approval)
```

---

### `plan.md`

Written by CTO after Gate 0 approval. PM reviews and signs before it goes to the user as Gate 1.

```markdown
---
task-id: <task-id>
status: draft | pm-approved | user-approved
pm-signed: <ISO date or blank>
user-approved: <ISO date or blank>
---

## Summary
[One sentence]

## Agents Involved
- Spec Specialist
- Backend-1, Backend-2 (or: Backend-1 only)
- Frontend-1 (or: not required)
- QA
- DevOps (or: not required)

## Gate Sequence

| Gate | Agent(s)        | Deliverable          | Acceptance Criteria                    |
|------|-----------------|----------------------|----------------------------------------|
| G-2  | Spec Specialist | spec.md              | All requirements captured, no gaps     |
| G-3  | Backend-1       | PR raised            | Tests pass, PM reviewed, no conflicts  |
| G-4  | QA              | Test results         | All acceptance criteria pass           |
| G-5  | DevOps          | Deployed to env      | Health check passes                    |

## Dependencies
- G-3 blocked by G-2 (spec must exist before implementation starts)
- G-4 blocked by G-3 (tests need code)
- G-5 blocked by G-4 (deploy after QA passes)

## PM Sign-Off Notes
[Filled by PM: any conflicts resolved, ownership assignments, scope clarifications]
```

---

### `gate-N.md`

Written by the agent completing the phase. CTO reads this to determine what to surface to the user.

```markdown
---
task-id: <task-id>
gate: <N>
label: <e.g. "Understanding Confirmation" | "Plan Approval" | "Spec Approval" | "Backend PR">
written-by: cto | pm | spec | backend-1 | backend-2 | frontend-1 | frontend-2 | qa | devops
status: pending | approved | rejected
approved-at: <ISO date or blank>
---

## What Was Done
[Summary of work completed in this phase]

## Deliverable
[Link or reference to the output: file path, PR URL, test report, etc.]

## Acceptance Criteria Met
- [ ] Criterion 1
- [ ] Criterion 2

## Next Phase (if approved)
[What happens after the user types /approve]

---
Type `/orch-approve` to confirm and advance, or `/orch-approve reject <feedback>` to revise.
```

---

### `mailbox.md` (per agent)

Written by CTO (or PM) to assign work. The execution agent reads this on start.

```markdown
---
task-id: <task-id>
project: <slug>
project-config: ~/.claude/orchestration/projects/<slug>.md
assigned-to: <role: spec | backend-1 | backend-2 | frontend-1 | frontend-2 | qa | devops>
assigned-by: cto
pm-approved: true | false
pm-approved-at: <ISO date or blank>
status: assigned | in-progress | complete | blocked
---

## Task
[Clear description of exactly what this agent must do]

## Input Files
- `brief.md` — the normalized brief
- `spec.md` — project spec (if available for this phase)
- [other relevant files]

## Expected Output
[Exactly what deliverable this agent produces and where to write it]

## Constraints
[Scope limits, tech stack, anything this agent must NOT do]

## Gate to Write
[Which gate-N.md this agent writes when done]

## Dependencies
[What must be done before this agent can start — e.g. "spec.md must exist"]
```

---

## Gate Status Lifecycle

```
pending → approved (user types /approve)
        → rejected (user provides corrections → CTO revises → re-submits)
```

## Task Status Lifecycle

```
pending-gate-0 → pending-gate-1 → active → pending-gate-N → complete
```

CTO updates `brief.md` status field as the task advances.

---

## Agent Naming in Mailboxes

When the CTO runs two Backend or Frontend agents in parallel, they are addressed as:
- `backend-1` and `backend-2`
- `frontend-1` and `frontend-2`

Each gets its own mailbox subdirectory. The CTO assigns non-overlapping scope to each.
The PM verifies there is zero overlap in scope before marking `pm-approved: true`.
