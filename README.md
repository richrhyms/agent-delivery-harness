# Agent Delivery Harness

A file-based, gate-driven system for running multi-agent software delivery in Claude Code. Eight role agents — spec, architecture, backend, frontend, QA, DevOps, plus a PM and an orchestrator — take a task from a GitHub issue or a plain prompt through to deployed code, with a human approval gate between every phase.

The point is not that agents write code. It's that the work is **scoped, structured, and verified** — each agent gets a bounded assignment, hands off through a defined schema rather than conversation, and nothing advances until a gate is approved.

---

## How it works

```mermaid
flowchart TD
    A["/orch &lt;issue | file | prompt&gt;"] --> B[brief.md]
    B --> C{{CTO}}
    C --> G0[["gate-0 · Understanding"]]
    G0 -->|/orch-approve| D{{CTO writes plan.md}}
    D --> PM{{PM reviews scope<br/>verifies zero overlap}}
    PM --> G1[["gate-1 · Plan"]]
    G1 -->|/orch-approve| SP{{Spec Specialist}}
    SP --> G2[["gate-2 · Spec"]]
    G2 -->|/orch-approve| AR{{Architect<br/>assigns module ownership}}
    AR --> G3[["gate-3 · Design"]]
    G3 -->|/orch-approve| IMP

    subgraph IMP["Implementation — parallel, non-overlapping scope"]
        direction LR
        BE1{{backend-1}}
        BE2{{backend-2}}
        FE1{{frontend-1}}
        FE2{{frontend-2}}
    end

    IMP --> G4[["gate-4a / 4b / 5 …"]]
    G4 -->|/orch-approve| QA{{QA Engineer}}
    QA --> V{Verdict}
    V -->|PARTIAL / FAIL| FIX{{Engineer fixes}}
    FIX --> REQA{{QA re-run}}
    REQA --> V
    V -->|PASS| DO{{DevOps}}
    DO --> G8[["gate-8 · Deployed"]]

    style G0 fill:#2d3748,color:#fff
    style G1 fill:#2d3748,color:#fff
    style G2 fill:#2d3748,color:#fff
    style G3 fill:#2d3748,color:#fff
    style G4 fill:#2d3748,color:#fff
    style G8 fill:#1a5f3f,color:#fff
    style V fill:#7c2d12,color:#fff
```

**Three properties worth calling out:**

**Gates are blocking.** Every phase ends with a gate file the user must approve. Deployment is declared dependent on a QA PASS in `plan.md`, and that dependency is enforced — an agent cannot advance past a failing gate.

**Parallel work is made safe by ownership, not coordination.** The Architect assigns explicit module ownership in `design.md`. The PM verifies zero scope overlap before marking any mailbox `pm-approved: true`. Agents are forbidden from editing files another instance owns, work on separate branches, and write to separate sub-gates (`gate-4a`, `gate-4b`) so their outputs cannot collide.

**Handoffs are schema'd, not conversational.** Every artifact — brief, plan, spec, design, mailbox, gate — has a defined schema in [`protocol.md`](./protocol.md). A malformed handoff fails at a boundary instead of silently corrupting everything downstream.

---

## Requirements

- **[Claude Code](https://claude.com/claude-code)** — this harness is Claude Code-native. It relies on subagent invocation and on `~/.claude/` discovery for agents and slash commands. It will not run as-is in other tools.
- **`git`**, and **`gh`** (GitHub CLI) if you want the DevOps role to raise PRs.
- macOS or Linux.

---

## Install

```bash
git clone https://github.com/richrhyms/agent-delivery-harness.git
cd agent-delivery-harness
./install.sh
```

`install.sh` symlinks the agent and command definitions into `~/.claude/` (symlinks, so `git pull` picks up updates), copies the protocol spec and config, and creates the runtime directories:

```
~/.claude/agents/orchestration/   ← 8 role agents      (symlinked)
~/.claude/commands/orch*.md       ← 6 slash commands   (symlinked)
~/.claude/orchestration/
├── protocol.md                   ← artifact schemas   (copied)
├── config.md                     ← agent roster       (copied)
├── projects/                     ← your project configs
├── active/                       ← in-progress tasks
└── archive/                      ← completed tasks
```

Runtime state (`projects/`, `active/`, `archive/`) stays out of the repo — it's your data, not shipped code.

> **Note:** the agent definitions reference `~/.claude/orchestration/` by absolute path, so the install location is fixed. See [Known gaps](#known-gaps).

---

## Quickstart

### 1. Configure a project (once per codebase)

```
/orch-setup my-project
```

Walks you through creating `~/.claude/orchestration/projects/my-project.md` — tech stack, repos, cloud and auth approach, health-check command, conventions. This is what lets the same role agents work across different codebases.

### 2. Start a task

```
/orch https://github.com/owner/repo/issues/42
/orch ./docs/some-spec.md
/orch "add rate limiting to the payments API"
```

Any of these normalize into a `brief.md` and hand off to the CTO, which writes **gate-0** — its understanding of what you actually asked for, before any work happens.

### 3. Approve through the gates

```
/orch-approve                      # advance
/orch-approve reject <feedback>    # send it back with corrections
```

After each approval the next phase runs and writes its own gate. You review, approve, repeat.

### 4. Check in or pick back up

```
/orch-status      # where is this task?
/orch-resume      # resume a task from wherever it stopped
```

### What to expect

The [worked example](#worked-example) — a 7-screen Next.js app with auth, a state machine, and live LLM calls — went from approved plan to deployed in **under a day**, and most of the elapsed time was waiting on gate approvals, not agent work.

---

## Commands

| Command | Purpose |
|---|---|
| `/orch <input>` | Start a task. Accepts a GitHub issue URL, `owner/repo#N`, a filepath, or a plain prompt. |
| `/orch-plan <input>` | Plan-only mode — produces the plan and stops. No implementation. |
| `/orch-approve` | Approve the current gate and advance. `reject <feedback>` sends it back. |
| `/orch-status` | Show current gate, active agents, and last action for a task. |
| `/orch-resume` | Resume an in-progress task from its last state. |
| `/orch-setup [project]` | Create or update a project config. |

---

## Roles

| Role | Owns | Max parallel |
|---|---|---|
| **CTO** | Orchestration, gate sequencing, mailbox assignment, `state.md` | 1 |
| **PM** | Reviews plans and scope assignments; verifies zero overlap before work starts | 1 |
| **Spec Specialist** | `spec.md` — requirements and acceptance criteria | 1 |
| **Architect** | `design.md` — API contracts, data models, **module ownership** | 1 |
| **Backend Engineer** | Server-side implementation within assigned scope | 2 |
| **Frontend Engineer** | UI implementation within assigned scope | 2 |
| **QA Engineer** | Verification against acceptance criteria; PASS / PARTIAL / FAIL | 1 |
| **DevOps Engineer** | Deployment and health verification | 1 |

Every role definition carries an explicit **NEVER DO** block — never work outside your mailbox scope, never start without `pm-approved: true`, never push or merge, never skip your gate file, never modify files another instance owns. In practice the negative constraints did more to make behaviour predictable than the positive instructions.

---

## Artifacts

Full schemas in [`protocol.md`](./protocol.md).

| File | Written by | Purpose |
|---|---|---|
| `brief.md` | `/orch` | Normalized input |
| `plan.md` | CTO, signed by PM | Gate sequence, agents involved, dependencies |
| `spec.md` | Spec Specialist | Requirements and acceptance criteria |
| `design.md` | Architect | API contracts, data models, module ownership |
| `state.md` | CTO | Navigation index — *derived, never the source of truth* |
| `gates/gate-N.md` | Phase owner | What was done, deliverable, criteria met, approval status |
| `agents/<role>/mailbox.md` | CTO / PM | Scoped assignment for one agent |

`state.md` exists purely as a context optimisation: rather than re-reading every gate file on each invocation, the CTO reads one index to know where it is. Gate files remain authoritative.

---

## Worked example

[`examples/unicorn-factory/`](./examples/unicorn-factory/) is a complete, unedited trace of a real run — brief, plan, spec, architecture, six mailboxes, and all ten gate files.

**What it produced:** a 7-screen Next.js 14 app with Supabase auth, a project state machine, and live LLM calls, deployed to production.

**Why it's the interesting part — QA blocked the deploy:**

| Gate | Verdict |
|---|---|
| `gate-6` — QA | **PARTIAL** — 27 pass, 1 fail, 2 skip |
| `gate-7-fix` — Backend | One-line fix: `.gitignore` had `.env*`, which silently swallowed `.env.example` |
| `gate-7-reqa` — QA re-run | **PASS** — 28 pass, 0 fail, 2 skip |
| `gate-8` — DevOps | Deployed |

The plan declared deployment dependent on a QA PASS, and the gate held. The defect was real: anyone cloning the repo would have had no setup template, and the README's instructions would have referenced a file that wasn't there.

**The two SKIPs matter as much as the fail.** QA marked `tsc --noEmit` and `npm run build` as SKIP *with a stated reason* — "requires a running environment" — rather than claiming a pass it couldn't prove. An agent that reports what it could not verify is worth considerably more than one that asserts success it never established.

---

## Known gaps

Stated plainly, because knowing where a system is weak is more useful than pretending it isn't.

- **QA is static review, not execution.** It reads code against acceptance criteria. It does not currently run the type checker, execute the build, start the app, or drive a browser. Those are exactly the two criteria it had to skip in the worked example. Closing this — real executable verification in the loop — is the highest-value next change.
- **No secret scanning.** Verification checks correctness, not credential hygiene.
- **Install path is fixed.** Agent definitions reference `~/.claude/orchestration/` by absolute path rather than resolving it from config.
- **Claude Code only.** The harness depends on Claude Code's subagent and command discovery model.
- **DevOps stops at the boundary.** Where deployment needs interactive shell access or tokens, the DevOps role emits a step-by-step runbook for a human rather than executing it.

---

## Repo layout

```
agents/         8 role definitions
commands/       6 slash commands
protocol.md     artifact schemas
config.md       agent roster, gate labels, runtime paths
examples/       complete trace of a real run
install.sh
```

---

## License

MIT
