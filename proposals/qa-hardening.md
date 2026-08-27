# DRAFT PROPOSAL — Hardening the QA Engineer role

> **Status:** DRAFT — for later review and possible action. Nothing here is implemented.
> **Scope:** `agents/qa-engineer.md`, `protocol.md` (project-config schema), `agents/cto.md` + QA mailbox template, `README.md` (Known Gaps).
> **Author:** architecture review, 2026-08-19
> **Problem addressed:** (1) model bias when quality-checking, (2) "static review only" verification.

---

## 1. Diagnosis (grounded in the current files)

Two root causes, both visible in the source:

### 1a. QA never has code to run
`agents/qa-engineer.md` Step 1 instructs QA to read PR **diffs** via
`gh api repos/<owner>/<repo>/pulls/<N>/files`. That returns a patch, not a working tree.
So although QA's frontmatter grants `Bash` and the prose says "run or review tests," there is
physically nothing checked out to execute. The mailboxes then make it explicit — e.g.
`examples/.../agents/qa/mailbox.md` (gate-7-reqa): *"Do not run the application."*

**Consequence:** in the worked example, `npx tsc --noEmit` (QA-18) and `npm run build` (QA-30)
were marked **SKIP**. Static-only is an **environment gap, not a capability gap.**

### 1b. The judge shares blind spots with the author
Engineers run `sonnet`; QA runs `sonnet` (both in agent frontmatter). Same model family judging
its own family produces **correlated blind spots** — what the implementer's model failed to handle
is disproportionately what the QA model won't think to check. QA also reads the engineers'
implementation **gate files** (their own claims of success) as input, inviting anchoring and the
leniency bias well documented for LLM-as-judge setups.

### Unifying insight
Both problems share a cure direction: **move verification from opinion to evidence.**
A green `tsc` exit code carries no model bias. The more "the judge's assessment" is replaced by
"a command's result," the less either problem bites. Track A (bias) and Track B (execution)
reinforce each other.

---

## 2. Track A — Reduce model bias in quality checking

| # | Change | Effort | Value |
|---|--------|--------|-------|
| A1 | **Diversify the judge from the implementer.** Change QA `model: sonnet → opus`. Different capability tier ⇒ fewer shared blind spots. If a second provider is ever wired in, prefer a judge from a different model family entirely. | Trivial | High |
| A2 | **Blind-first evaluation.** Build the per-AC check list from `spec.md` + `design.md` (independent oracles) **before** reading the engineers' gate narratives; read their claims only afterward to reconcile. Removes the anchoring path. | Low | High |
| A3 | **Adversarial stance.** For each AC require QA to *construct a failure* (edge case, boundary, malformed input) and show it's handled — not assert the happy path. Counters leniency bias. | Low | High |
| A4 | **Ban opinion-only PASS.** An executable AC may be `PASS` only on a command result; inspection maps to `UNTESTABLE`/`SKIP` **with a reason**, never PASS. | Low | Med |
| A5 | **(Optional) Dual-judge escalation.** For high-stakes tasks, run QA twice (different model or framing); auto-PASS only on agreement, disagreement escalates to the human. Gate behind a `plan.md` flag — it doubles QA cost. | Med | Situational |

---

## 3. Track B — Replace "static review only" with real execution

| # | Change | Effort | Value |
|---|--------|--------|-------|
| B1 | **Give QA a working tree.** Before validation, `gh pr checkout <N>` (or clone + checkout the branch) into the project dir. Precondition for everything else. | Low | High |
| B2 | **Executable contract lives in project config, not the agent.** Extend the config (which already abstracts `health-check-cmd`) with a `## Verification Commands` block so the agent stays project-agnostic across Node / Python / Salesforce / etc. | Low | High |
| B3 | **Execute-first posture.** For each AC, attempt an executable proof (run the test / `tsc` / build / `curl`), fall back to `UNTESTABLE` only when no environment path exists. The worked example's SKIPs become real PASS/FAIL. | Med | High |
| B4 | **Sandbox the run.** This is executing untrusted PR code — do checkout+run in an ephemeral git **worktree** or container: no real secrets (use `.env.example` values), network-restricted, with a timeout. Also brushes against the README's "no secret scanning" gap. | Med | High (safety) |
| B5 | **Minimal frontend smoke.** `build` + boot + one headless Playwright check ("primary screen renders, key flow doesn't throw"). Degrades gracefully when `e2e-cmd: none`. | Med | Med |

### Proposed `## Verification Commands` block (protocol.md project-config schema)

```markdown
## Verification Commands
- install-cmd:   <e.g. npm ci>
- typecheck-cmd: <e.g. npx tsc --noEmit>
- build-cmd:     <e.g. npm run build>
- test-cmd:      <e.g. npm test>
- lint-cmd:      <e.g. npm run lint>
- e2e-cmd:       <e.g. npx playwright test  |  none>
```

QA runs exactly these — the same abstraction pattern the config already uses for deploy/health,
so one QA agent keeps working across codebases.

---

## 4. Concrete edits (when actioned)

- **`agents/qa-engineer.md`**
  - `model: sonnet → opus` (A1)
  - reorder steps to blind-first (A2)
  - add adversarial rubric (A3) + no-opinion-PASS rule (A4)
  - add checkout + execute-in-worktree step (B1, B3, B4)
  - read verification commands from project config (B2)
- **`protocol.md`** — add `## Verification Commands` to the project-config schema (B2)
- **`agents/cto.md` + QA mailbox template** — remove "do not run the application"; pass the
  verification-command set and the sandbox instruction into the QA mailbox
- **`README.md` "Known gaps"** — update; this closes the item it calls
  *"the highest-value next change."*

---

## 5. Suggested phasing

1. **Phase A first** (A1–A4): low-risk, high-return, no new infrastructure. Land on a branch,
   review, merge.
2. **Phase B next** (B1–B5): bigger lift — depends on QA reliably reproducing each project's
   environment (the fiddly part, which is why B2's clean `install-cmd` and B4's sandbox matter).
3. **A5 last**, only if dual-judge cost is justified for certain task classes.

---

## 6. Open questions for review

- Is opus acceptable cost for every QA run, or should judge-tier be a `plan.md`-level choice?
- Worktree vs container for the sandbox (B4) — what's already available/preferred in the target env?
- Should `e2e-cmd` be mandatory for frontend-touching plans, or always opt-in?
- Does "execute untrusted PR code" need an explicit human opt-in gate for external contributors?

---

## 7. Caveat

Track B's value is real but its reliability hinges on environment reproduction. If `install-cmd`
is flaky or the sandbox can't reach a needed service, QA will regress to `UNTESTABLE` — which is
still honest, but not the win. Track A delivers regardless and should not be blocked on Track B.
