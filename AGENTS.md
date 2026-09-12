# AGENTS.md — cloudwatchsyntheticcanary

Context for AI coding agents (Claude Code, Codex, opencode, Cursor, …) working in this
repo. Read this first; there is no `README`, so this file is the entry point.

## What this is — ⚠️ RETIRED
A Terraform + CUE stack that deployed CloudWatch Synthetics canaries (browser / API / Domino
Data Lab) with alarms and SNS alerting.

**Retired 2026-08-24:** every AWS resource in this repo was destroyed, and the
`Deploy Synthetic Canaries` workflow was **disabled** (GitHub Actions state
`disabled_manually`). Note the YAML still carries `push`/`workflow_dispatch` triggers, so
re-enabling it in the Actions tab would redeploy the whole stack.

**`synth-canary-template` (public, self-contained at `modules/synthetic-canary/`) is the
source of truth going forward — make all canary code/config changes there, not here.** Keep
this repo for reference/history unless told otherwise.

## Layout
- `cue/` (`canary.cue`, `canaries.cue`) — canary config as code. CI compiles it to
  `cloudwatch_map.auto.tfvars.json` (gitignored, generated — never hand-edit).
- `main.tf` / `canary_source.tf` — build each canary's zip from `src/*.py` (the zip filename
  embeds the source hash) and instantiate `modules/synthetic-canary`.
- `modules/synthetic-canary/` — the reusable canary module (canary, alarm, SNS, execution role).
- `src/` — `api_canary.py` (generic, env-parameterized), `domino_canary.py`, `google.py`,
  `youtube.py`.
- `iam.tf`, `s3.tf`, `vpc.tf`, `policies/` (`*.json` / `*.tftpl`), `versions.tf`, `backend.tf`,
  `provider.tf`.
- `.github/workflows/` — `ci.yml`, `deploy_and_run.yml` (disabled), `destroy.yml`,
  `release.yml`; plus `.checkov.baseline`, `.tflint.hcl`, `.github/dependabot.yml`.

## Commands
- **Terraform is applied via GitHub Actions only — never locally.**
- CI (`ci.yml`) runs on PR + push to `master`: Terraform fmt/validate, CUE vet + export,
  tflint, checkov, and a plan.
- Teardown was `workflow_dispatch` → `destroy.yml`.
- Local Terraform isn't expected on this host; validate via CI (or Docker).

## Conventions
- Default branch is **`master`**, not `main`.
- State: `s3://emr-demo-state-zxcvzxcv23/cloudwatchsyntheticcanary/terraform.tfstate`
  (us-east-2); provider region `us-east-1`; OIDC role `github-actions-oidc-role`.
- No inline JSON in HCL — policies live in `policies/*.json` / `*.tftpl`.
- Public-safe repo: committed config uses placeholder emails; real alarm recipients are
  injected from repo secrets at deploy time. Never commit real addresses or keys.
- Feature branch → PR → merge; never push to `master` directly.

## Gotchas
- **`cloudwatch_map` has no default** — it comes from the CUE export. Every `terraform`
  command (plan *and* destroy) needs
  `cue export ./cue --out json > cloudwatch_map.auto.tfvars.json` first, or it fails with
  "No value for required variable". `destroy.yml` learned this the hard way.
- `aws_synthetics_canary` diffs only the zip **path**, not its contents, which is why the
  source hash is baked into the zip filename in `canary_source.tf`. Preserve that behavior.
- Per-canary `timeout_in_seconds` matters: AWS caps 300s on ≤5-minute schedules, and the
  Domino workspace poll needs 600s.
- Keep the retirement note intact if you add docs here.
