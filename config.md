# Orchestration Project Config

This file provides project-level defaults for the orchestration system.
The `/orch` skill and CTO agent read this on every invocation.

---

## Agent Roster

| Role | Agent File | Max Parallel Instances |
|------|------------|------------------------|
| Spec Specialist | `~/.claude/agents/orchestration/spec-specialist.md` | 1 |
| Architect | `~/.claude/agents/orchestration/architect.md` | 1 |
| Backend Engineer | `~/.claude/agents/orchestration/backend-engineer.md` | 2 (backend-1, backend-2) |
| Frontend Engineer | `~/.claude/agents/orchestration/frontend-engineer.md` | 2 (frontend-1, frontend-2) |
| QA Engineer | `~/.claude/agents/orchestration/qa-engineer.md` | 1 |
| DevOps Engineer | `~/.claude/agents/orchestration/devops-engineer.md` | 1 |
| PM | `~/.claude/agents/orchestration/pm.md` | 1 |
| CTO | `~/.claude/agents/orchestration/cto.md` | 1 |

---

## Gate Labels

| Gate | Default Label |
|------|---------------|
| 0 | Understanding Confirmation |
| 1 | Plan Approval |
| 2 | Spec Approval |
| 3 | Design Approval (Architect gate — present in standard flow, omitted in fast-track) |
| 4+ | Assigned dynamically by CTO in plan.md |

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
