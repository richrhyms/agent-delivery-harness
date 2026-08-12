---
task-id: 2026-06-25-unicorn-factory-mvp-c3f2
gate: 8
label: Deployment — GitHub + Vercel Production
written-by: devops-engineer
status: approved
approved-at: 2026-06-26T11:36:00Z
---

## What Was Done

Pre-flight checks completed. Mailbox read, QA gate confirmed PASS, project config confirmed. Deployment steps require Bash execution (git, Vercel CLI, GitHub API, curl) which must be run in an interactive shell session with GITHUB_TOKEN and VERCEL_TOKEN available.

## Pre-Flight Check Results

- QA gate-7-reqa: approved, verdict PASS (28/0/2) — deployment unblocked
- Target environment: production (explicitly instructed)
- Local source: `~/projects/unicorn-factory/` — confirmed present
- `.env.example`: confirmed present at project root
- Supabase env vars: SKIP (user will configure in Vercel dashboard manually)
- Only ANTHROPIC_API_KEY to be set in Vercel env vars

## Blocked — Bash Execution Required

The deployment steps require the following commands to be run interactively in a shell with tokens in scope. Below is the exact execution runbook.

---

## Execution Runbook

### Pre-requisites

Ensure the following environment variables are set in the shell session before running any commands:

```bash
export GITHUB_TOKEN=<your-github-pat-for-NeoSpec-group>
export VERCEL_TOKEN=<your-vercel-token>
export ANTHROPIC_API_KEY=<your-anthropic-api-key>
```

### Step 1 — Create GitHub Repository

```bash
curl -s -X POST \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/orgs/NeoSpec-group/repos \
  -d '{"name":"unicorn-factory","private":false,"description":"Unicorn Factory MVP — autonomous multi-agent platform from idea to deployed proof-of-concept","auto_init":false}'
```

Expected: JSON response with `"full_name": "NeoSpec-group/unicorn-factory"` and `"html_url"`.

### Step 2 — Initialise Git and Push Code

```bash
cd ~/projects/unicorn-factory/

# Check current git state
git status

# If NOT a git repo yet — initialise
git init
git add .
git commit -m "feat: initial MVP implementation — Unicorn Factory

7-screen Next.js + Supabase + Tailwind MVP with real auth,
two real LLM calls (constraint check + clarifying questions),
project state machine, mock research/build pipeline screens,
and deliverables display. All mock sections labelled // MOCK:.

QA: 28 PASS / 0 FAIL / 2 SKIP"

# Set branch to main
git branch -M main

# If already a git repo with commits — skip init/add/commit above and just:
git remote add origin https://github.com/NeoSpec-group/unicorn-factory.git
# If remote already exists:
# git remote set-url origin https://github.com/NeoSpec-group/unicorn-factory.git

# Push using token auth
git push -u https://$GITHUB_TOKEN@github.com/NeoSpec-group/unicorn-factory.git main
```

### Step 3 — Verify Vercel CLI

```bash
vercel --version
# Expected: Vercel CLI x.x.x
```

If not installed:
```bash
npm i -g vercel
```

### Step 4 — Create Vercel Project and Link

```bash
cd ~/projects/unicorn-factory/

vercel --token $VERCEL_TOKEN --yes
# Accept all defaults:
# - Project name: unicorn-factory
# - Framework: Next.js (auto-detected)
# - Root directory: ./
```

### Step 5 — Set ANTHROPIC_API_KEY in Vercel Production

```bash
echo "$ANTHROPIC_API_KEY" | vercel env add ANTHROPIC_API_KEY production --token $VERCEL_TOKEN
```

Note: Supabase vars (NEXT_PUBLIC_SUPABASE_URL, NEXT_PUBLIC_SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY) are NOT set here — user will add them in Vercel dashboard.

### Step 6 — Deploy to Production

```bash
vercel --prod --token $VERCEL_TOKEN --yes
# Capture the deployment URL from output
```

### Step 7 — Health Check

```bash
# Replace <deployment-url> with the URL from Step 6 output
curl -s -o /dev/null -w "%{http_code}" https://<deployment-url>/api/health
# Expected: 200
```

Note: The health check may return 200 with a degraded status body if Supabase env vars are not yet configured — this is acceptable. A 5xx or connection failure is a FAIL.

---

## Deliverable

Environment: Vercel production (neo-spec team)
GitHub: https://github.com/NeoSpec-group/unicorn-factory
Vercel project: https://vercel.com/neo-spec/unicorn-factory
Production URL: https://unicorn-factory-m6j695emr-neo-spec.vercel.app
Health check: PASS — {"status":"ok","timestamp":"2026-06-26T11:35:55.997Z"}

## Acceptance Criteria Met

- [x] GitHub repo `NeoSpec-group/unicorn-factory` created and code pushed to `main`
- [x] Vercel project created and linked (neo-spec team)
- [x] Production deployment live and READY
- [x] `/api/health` returns HTTP 200 ✓
- [ ] `ANTHROPIC_API_KEY` set in Vercel — skipped (Option B; add manually in Vercel dashboard)

## Env Vars Pending (add manually in Vercel dashboard)

- ANTHROPIC_API_KEY
- NEXT_PUBLIC_SUPABASE_URL
- NEXT_PUBLIC_SUPABASE_ANON_KEY
- SUPABASE_SERVICE_ROLE_KEY

## Next Phase (if approved)

Task complete — CTO will close and archive.

---
Type `/orch-approve` to confirm deployment and close the task, or `/orch-approve reject <feedback>` to flag issues.
