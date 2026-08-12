---
task-id: 2026-06-25-unicorn-factory-mvp-c3f2
agent: devops-engineer
gate: 8
pm-approved: true
pm-approved-at: 2026-06-26T09:30:00Z
project: unicorn-factory
project-config: ~/.claude/orchestration/projects/unicorn-factory.md
---

## Task

Deploy the Unicorn Factory MVP to production. QA has passed (28 PASS / 0 FAIL / 2 SKIP). This is the final gate.

## Steps (execute in order)

### 1. Create GitHub Repository

- GitHub org: **NeoSpec-group**
- Repo name: **unicorn-factory**
- Visibility: public
- Do NOT initialise with README, .gitignore, or licence — the local repo already has all of these
- A GitHub Personal Access Token is available in-session. Read it from the environment variable `GITHUB_TOKEN` or ask the user to echo it into your session context if not available. Do NOT hardcode any token.

Use the GitHub REST API (or `gh` CLI if authenticated):
```
POST https://api.github.com/orgs/NeoSpec-group/repos
Authorization: Bearer <GITHUB_TOKEN>
Body: { "name": "unicorn-factory", "private": false }
```

### 2. Push Local Code to GitHub

Local source directory: `~/projects/unicorn-factory/`

Steps:
1. `cd ~/projects/unicorn-factory/`
2. Verify it is a git repo (`git status`)
3. Add the remote: `git remote add origin https://github.com/NeoSpec-group/unicorn-factory.git`
   - If remote `origin` already exists, update it: `git remote set-url origin https://github.com/NeoSpec-group/unicorn-factory.git`
4. Push: `git push -u origin main` (use the token for auth — set `GIT_ASKPASS` or pass credentials inline via `https://<GITHUB_TOKEN>@github.com/NeoSpec-group/unicorn-factory.git`)

### 3. Create Vercel Project and Deploy

A Vercel token is available in-session. Read it from the environment variable `VERCEL_TOKEN`. Do NOT hardcode any token.

Steps:
1. Confirm Vercel CLI is installed: `vercel --version`
2. Link or create the Vercel project:
   ```
   cd ~/projects/unicorn-factory/
   vercel --token $VERCEL_TOKEN --yes
   ```
   - When prompted for project name: `unicorn-factory`
   - Framework: Next.js (Vercel should auto-detect)
   - Root directory: `.` (repo root)
   - Do NOT override build/output settings — accept defaults
3. Set the production environment variable:
   ```
   vercel env add ANTHROPIC_API_KEY production --token $VERCEL_TOKEN
   ```
   - The value to set: read from the local environment variable `ANTHROPIC_API_KEY` in the current session. If not present in the environment, read from `~/projects/unicorn-factory/.env` (the `ANTHROPIC_API_KEY` line). Do NOT hardcode the value.
   - **Supabase env vars (NEXT_PUBLIC_SUPABASE_URL, NEXT_PUBLIC_SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY):** SKIP — user will configure these manually in the Vercel dashboard.
4. Trigger production deployment:
   ```
   vercel --prod --token $VERCEL_TOKEN --yes
   ```
5. Capture the deployment URL from the output (format: `https://unicorn-factory-<hash>.vercel.app` or `https://unicorn-factory.vercel.app`).

### 4. Verify Health Check

Run:
```
curl -f https://<deployment-url>/api/health
```

Expected: HTTP 200 with a JSON body. If the endpoint returns 200, health check is PASS.

Note: The `/api/health` route may return an error if Supabase env vars are not configured (the user will add them manually). If the health endpoint itself returns 200 (even with a degraded status body), consider the deployment PASS. If it returns a 5xx or connection error, record as FAIL and report.

## Constraints

- Do NOT modify any source files — only deploy what is already in the local directory
- Do NOT commit any new code
- Do NOT create or modify any `.env` files in the repo
- All tokens must be read from environment variables — never written to files or echoed to git
- Target environment: **production** (explicitly requested by user)

## Expected Gate Deliverable

Gate file: `~/.claude/orchestration/active/2026-06-25-unicorn-factory-mvp-c3f2/gates/gate-8.md`

The gate file must include:
- GitHub repo URL: `https://github.com/NeoSpec-group/unicorn-factory`
- Vercel deployment URL
- Health check result (PASS / FAIL)
- Full deployment log with commands and key output lines

## Reference Files

- QA gate (approved PASS): `~/.claude/orchestration/active/2026-06-25-unicorn-factory-mvp-c3f2/gates/gate-7-reqa.md`
- QA report: `~/projects/unicorn-factory/docs/qa-report.md`
- Project config: `~/.claude/orchestration/projects/unicorn-factory.md`
