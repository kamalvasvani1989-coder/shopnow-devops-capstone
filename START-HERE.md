# ShopNow Capstone - End-to-End DevOps Pipeline (Jenkins -> EKS) under $30

This package = the original ShopNow app **plus everything the team needs to build**:
Terraform, Ansible, Jenkins pipelines, Kubernetes manifests, monitoring, tests and doc templates.
The full step-by-step plan (cost table, team split, every sprint, troubleshooting) is
**[docs/CAPSTONE-PLAN.pdf](docs/CAPSTONE-PLAN.pdf)** - read sections "Read this first" and "Architecture and cost plan" before anything else.

## The one rule
The EKS cluster exists only while someone is working. It is created by Jenkins at the start of a
session and destroyed at the end (and automatically at 23:00 IST by `99-nightly-destroy`).
Following this keeps the project at roughly **$20 of the $30** budget.

## What changed vs the original repo
| File | Change | Why |
| --- | --- | --- |
| `frontend/Dockerfile`, `admin/Dockerfile` | `node:20` / `nginx:1.27`; `PUBLIC_URL=/`, `REACT_APP_API_BASE_URL=/api` build args | Old `USER_NAME=aryan` made the app live under `/aryan`; empty value produced `//api`. node:18 is end-of-life. |
| `admin/nginx/default.conf` | Added `location /api/` proxy | Admin app calls `/api/...`, config only proxied `/admin/` |
| `backend/Dockerfile` | `node:20`, `npm ci --omit=dev`, healthcheck on `/api/health` | Deprecated flag, wrong health path |
| `backend/server.js`, `package*.json` | `express-prom-bundle` -> `/metrics` | Prometheus request rate / errors / latency |

## Folder map
| Folder | Owner | Used in |
| --- | --- | --- |
| `infra/bootstrap/` | M1 | Step 0 - run ONCE from AWS CloudShell: ECR, Jenkins IAM role, Jenkins EC2 |
| `infra/platform/` | M1 | Sprint 2 - run BY JENKINS: VPC, EKS (Spot), tools EC2, VPC peering, Grafana IAM |
| `jenkins/` + root `Jenkinsfile` | M2 | `01-infra-terraform`, `02-config-ansible`, `03-shopnow-cicd`, `99-nightly-destroy` |
| `ansible/` | M4 | `jenkins-host.yml` (Sprint 1), `site.yml` (Sprint 3) |
| `k8s/` | M3 | Sprint 4 - Deployments, Services, HPA, ServiceMonitor |
| `monitoring/` | M4 | Sprint 5 - Helm values, alert rules, Grafana dashboards |
| `tests/` | M3 | smoke test, infra check, pre-destroy cleanup |
| `scripts/` | all | session start / webhook update / end-of-session checks |
| `docs/` | all | plan PDF + chapter templates (15% of the grade) |

## Placeholders to replace before first use
Search the repo for these and replace them:
- `<ACCOUNT_ID>` -> your 12-digit AWS account ID (in both `versions.tf` files)
- `infra/bootstrap/terraform.tfvars` -> copy from `terraform.tfvars.example`, put each member's public IP
- `infra/platform/envs/dev.tfvars` -> each member's IAM user ARN (for kubectl access)
- `ansible/group_vars/all.yml` + `infra/platform/variables.tf` -> `k8s_minor` / `cluster_version` = newest EKS version in **standard** support
- `infra/bootstrap/jenkins-userdata.sh` -> verify the Jenkins apt key URL against jenkins.io

## Order of work
1. **Step 0** (M1): budgets + alerts, IAM users with MFA, key pair `shopnow-key`, state bucket, `infra/bootstrap` apply.
2. **Sprint 1** (M2/M3/M4): `sudo ansible-playbook -i localhost, -c local ansible/jenkins-host.yml` on Jenkins, plugins, credentials, webhook, job `03-shopnow-cicd` builds + pushes images.
3. **Sprint 2** (M1/M2): jobs `01-infra-terraform` and `99-nightly-destroy`; two clean apply/destroy cycles.
4. **Sprint 3** (M4/M2): job `02-config-ansible`; runs automatically after apply.
5. **Sprint 4** (M3/M2): full pipeline to EKS, HPA, rollback test.
6. **Sprint 5** (M4): dashboards + Slack alerts.
7. **Sprint 6** (all): tests T01-T14, docs, two recorded end-to-end runs.

## Jenkins credentials to create (IDs must match)
`github-pat`, `ec2-ssh-key` (user `ubuntu`), `mongodb-uri`, `slack-webhook` (Alertmanager), `grafana-admin`,
plus a Slack bot token configured under Manage Jenkins -> System -> Slack (used by `slackSend`).
No AWS keys - Jenkins uses its instance role.

## Daily routine
```
bash scripts/session-start.sh <jenkins-id>
GH_PAT=... bash scripts/update-webhook.sh <jenkins-id> prassanaganesh/<repo> <hook-id>
Jenkins: 01-infra-terraform  ACTION=apply ENV=dev       (config + deploy follow automatically)
... work ...
Jenkins: 01-infra-terraform  ACTION=destroy ENV=dev
bash scripts/session-end-check.sh
aws ec2 stop-instances --instance-ids <jenkins-id>
```

## Not validated here
These files were written and syntax-checked (YAML/JSON/bash), but not run against AWS.
Expect small fixes on first run - log them in `docs/09-troubleshooting.md`.
