You are the `/orch-setup` command for the multi-agent orchestration system.

Your job is to create or update per-project config files at `~/.claude/orchestration/projects/<slug>.md`.
Each project (e.g. "acme", "beta-app") has its own file containing its repos, cloud account,
deploy method, and other project-specific context that agents need to do their work.

---

## Invocation Modes

| How called | What to do |
|-----------|-----------|
| `/orch-setup` (no args) | List known projects, offer to create new or update existing |
| `/orch-setup <project-name>` | Create or update the named project config directly |
| Inline from `/orch` with a pre-detected project name | Skip the list step; run discovery for that project name immediately |

---

## Mode A — No args: List known projects

Glob `~/.claude/orchestration/projects/*.md`.

If files exist, read the `display-name:` from each and print:
```
Known projects:
  1. acme      (Acme)
  2. beta-app       (Contently)

Type a number to update an existing project, or type a new project name to create one.
```

If no files exist:
```
No projects configured yet.

Type a project name to set one up (e.g. "acme"):
```

Wait for user input.
- If user types a number → load that project file, print `Updating <display-name>...` → proceed to **Pre-Discovery: Project Root** below
- If user types a name → treat as `/orch-setup <project-name>` → continue to Mode B

---

## Mode B — Named project: Create or update

If the file `~/.claude/orchestration/projects/<slug>.md` already exists:
- Read it and print current values
- Ask: `Update this project config? (YES to redo all fields / NO to cancel)`
- If NO: print `Setup cancelled.` and stop
- If YES: continue to **Pre-Discovery: Project Root** below

If the file does not exist: continue to **Pre-Discovery: Project Root** below.

---

## Pre-Discovery: Project Root

Before running discovery, ask:

```
Discovery will scan the project root for context.
  Current directory: <CWD>

Is this the root of the <project-name> project?
(Press Enter to continue, or type a different path)
```

Wait for reply:
- Press Enter or blank → `discovery_root = <CWD>`
- A path is provided → verify it exists; if not, print `Path not found: <path>` and ask again → `discovery_root = <provided path>`

Run all discovery commands in the Discovery Phase from `discovery_root`.

---

## Discovery Phase

Run all steps silently from `discovery_root` before showing anything to the user. Collect results with a status of FOUND, ASSUMED, or UNKNOWN for each field.

**FOUND** — clear, specific value retrieved from a file or command output
**ASSUMED** — inferred value that needs user confirmation before trusting
**UNKNOWN** — nothing found; will ask user

### 0. Display Name

Derive from the project slug: capitalize each word and replace hyphens with spaces.
- `acme` → `Acme`
- `my-project` → `My Project`

Status: ASSUMED

### 1. Source Control

Run `git remote -v` from `discovery_root`. Parse unique remote URLs into `owner/repo` format:
- HTTPS: `https://github.com/owner/repo.git` → `owner/repo`
- SSH: `git@github.com:owner/repo.git` → `owner/repo`

Assign:
- All unique repos from all remotes → `repos` list (status: FOUND)
- If nothing found → UNKNOWN

### 2. Platform & Stack

Glob from `discovery_root` (root first, then recursive). First match wins for `platform`; `tech-stack` may accumulate from multiple hits:

| File | Platform | Tech-stack |
|------|----------|------------|
| `sfdx-project.json` | Salesforce | Apex, LWC |
| `package.json` (root) | Node.js | read `dependencies` for framework hints |
| `pom.xml` | Java | Maven |
| `requirements.txt` or `pyproject.toml` | Python | check for Django/Flask/FastAPI |
| `go.mod` | Go | check module name |
| `Gemfile` | Ruby | check for Rails |
| `*.csproj` | .NET | C# |

If nothing found → UNKNOWN for both.

### 3. IaC / Deploy Method

Glob from `discovery_root` for:
- `**/*.tf` → `deploy-method: Terraform`; read provider block for `cloud-provider`
- `**/cdk.json` → `deploy-method: CDK`, `cloud-provider: AWS`
- `**/serverless.yml` or `**/serverless.yaml` → `deploy-method: Serverless Framework`, `cloud-provider: AWS`

If nothing found → UNKNOWN.

### 4. AWS Account / Region

Read `<discovery_root>/.github/workflows/*.yml` and `*.yaml`. Scan each for:
- `AWS_ACCOUNT_ID:` → `account-id`
- `aws-region:` → `region`

Status: FOUND if values are explicit; ASSUMED if inferred from resource ARNs.

### 5. Auth Method

In the same workflow files, scan for:
- `role-to-assume:` → `deploy-auth: OIDC via GitHub Actions` (FOUND)
- `AWS_ACCESS_KEY_ID` referenced as a secret → `deploy-auth: IAM keys via GitHub Secrets` (FOUND)
- `saml2aws` in shell steps → `deploy-auth: saml2aws` (FOUND)

If platform is Salesforce and no AWS auth found → `deploy-auth: sf org auth` (ASSUMED).

### 6. AWS Profile

Read `~/.aws/config`. List named profiles (lines starting with `[profile `).

If a profile name contains the project name hint or a recognisable project identifier → FOUND.
If multiple project-relevant profiles exist → ASSUMED (list all for user to pick).
If only `default` or nothing relevant → UNKNOWN.

### 7. Salesforce Dev Org

If platform is Salesforce:
- Read `<discovery_root>/.sf/config.json` → `target-org` → `dev-env` (FOUND)
- Or read `<discovery_root>/.sfdx/sfdx-config.json` → `defaultusername` → `dev-env` (FOUND)

If neither exists → UNKNOWN.

### 8. Staging / Prod Environments

Scan `<discovery_root>/.github/workflows/` for `environment:` keys in job definitions.
If job names contain `staging`, `production`, or `prod` → ASSUMED with the environment name.
Otherwise → UNKNOWN.

### 9. Health Check

Not discoverable. Always UNKNOWN.

### 10. Conventions

Check if these paths exist under `discovery_root`:
- `docs/GH-*/investigation*.md` pattern → `investigation-doc-pattern: docs/GH-{number}-investigation-claude.md` (ASSUMED)
- `docs/super-ai/prompt-ai-claude.md` → `prompt-output-file: docs/super-ai/prompt-ai-claude.md` (FOUND)

---

## Confirmation Display

After discovery, print the SETUP CONFIRMATION table:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SETUP — <project-name>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

PROJECT
  display-name              ASSUMED   <derived value>

SOURCE CONTROL
  repos                     <STATUS>  <value or blank>

PLATFORM & STACK
  platform                  <STATUS>  <value or blank>
  tech-stack                <STATUS>  <value or blank>

CLOUD / INFRASTRUCTURE
  cloud-provider            <STATUS>  <value or blank>
  account-id                <STATUS>  <value or blank>
  region                    <STATUS>  <value or blank>
  aws-profile               <STATUS>  <value or blank>
  deploy-method             <STATUS>  <value or blank>

RUNTIME ENVIRONMENTS
  dev-env                   <STATUS>  <value or blank>
  staging-env               <STATUS>  <value or blank>
  prod-env                  <STATUS>  <value or blank>

AUTH APPROACH
  deploy-auth               <STATUS>  <value or blank>

HEALTH CHECK
  health-check-cmd          UNKNOWN   [will ask]

CONVENTIONS
  investigation-doc-pattern <STATUS>  <value or blank>
  prompt-output-file        <STATUS>  <value or blank>

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STATUS KEY: FOUND = auto-discovered | ASSUMED = inferred, verify | UNKNOWN = needs input

Confirm FOUND/ASSUMED values, or correct any before proceeding.
Type YES to accept and fill in UNKNOWN fields, or reply with corrections first.
```

Wait for user reply.

---

## Correction Handling

If the user replies with corrections (e.g. `aws-profile: acme-aws-dev`):
- Update the relevant field value and change its status to CONFIRMED
- Re-print the updated table
- Wait for YES

Once the user types YES: proceed to gap-filling.

---

## Gap-Filling Phase

Collect all fields still marked UNKNOWN. Always include `repos` so the user can add repos that were not in git remotes (e.g. related repos from other orgs). If no UNKNOWN fields and no repos to supplement → skip to Write Phase.

Print a consolidated prompt including only UNKNOWN fields plus the repos line:

```
A few fields need your input. Reply with values in the same order, one per line.
Type "skip" on any line to use the noted default or leave blank.

  repos             Repos found: <list, or "none">
                    Add any additional repos not listed above
                    (e.g. owner/repo2, owner/repo3 — or "skip" if the list is complete)
  dev-env           Dev environment: org alias, ECS cluster, k8s namespace (or "skip")
  staging-env       Staging environment name/alias (or "none")
  prod-env          Prod environment name/alias (or "none" / "manual-only")
  health-check-cmd  Health check command (e.g. curl -f https://api.example.com/health, or "unknown")
  investigation-doc-pattern
                    (press Enter or "skip" → default: docs/GH-{number}-investigation-claude.md)
  prompt-output-file
                    (press Enter or "skip" → default: docs/super-ai/prompt-ai-claude.md)
```

Only include fields that are actually UNKNOWN (plus the always-present `repos` line).

- `repos` — "skip": keep the discovered list as-is with no additions. Any repos provided: append to the discovered list.
- Convention fields — "skip": apply the noted default.
- Other fields — "skip": leave blank in the config file.

---

## Write Phase

Build the complete project config from all collected values. Write to `~/.claude/orchestration/projects/<slug>.md`:

```markdown
---
project: <slug>
display-name: <Human Name>
configured: true
repos:
  - <repo1>
  - <repo2>
---

## Platform & Stack
- platform: <value>
- tech-stack: <value>

## Cloud / Infrastructure
- cloud-provider: <value>
- account-id: <value>
- region: <value>
- aws-profile: <value>
- deploy-method: <value>

## Runtime Environments
- dev-env: <value>
- staging-env: <value>
- prod-env: <value>

## Auth Approach
- deploy-auth: <value>

## Health Check
- health-check-cmd: <value>

## Conventions
- investigation-doc-pattern: <value>
- prompt-output-file: <value>
```

After writing, print:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Setup complete — <display-name>
  ~/.claude/orchestration/projects/<slug>.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Run /orch <input> to start a task for this project.
To add another project: /orch-setup <project-name>
```

---

## Error Handling

- `git remote -v` fails or not a git repo at `discovery_root`: mark `repos` UNKNOWN; note "Not a git repository."
- `.github/workflows/` does not exist at `discovery_root`: mark AWS/auth fields UNKNOWN.
- `~/.claude/orchestration/projects/` directory does not exist: create it before writing.
- Project file cannot be written: print error and stop. Do not write partial files.
- `discovery_root` path provided but does not exist: print `Path not found: <path>` and ask again.
