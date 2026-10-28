# 01 — Account guardrails and bootstrap (persistent layer)

## Purpose
Prepare the AWS account safely and create the long-lived resources that the pipeline needs before it can run: Terraform remote state, ECR repositories and the Jenkins server.

## Prerequisites
- Windows laptop with Git, AWS CLI v2, kubectl, GitHub CLI and Terraform (`winget install …`), shell UCRT64/Git Bash.
- AWS account (Free plan, region **ap-southeast-2**); IAM user `kamal-admin` with an access key on CLI profile `capstone`.
- `.capstone-env` in the repo root (git-ignored): `export AWS_PROFILE=capstone`, `JENKINS_ID`, `HOOK_ID`.

## Setup steps
1. **Guardrails:** MFA on the sign-in; daily cost budget `capstone-daily-7usd` (alert at 80 %); Cost Anomaly Detection (default monitor). Baseline cost captured before starting (`evidence/B-cost-before-capstone.txt`).
2. **Constraint probing (read-only / dry-run):** region access, EKS create probe, Spot and On-Demand dry runs, vCPU quotas, free-tier instance types (`evidence/B-free-tier-instance-types.txt`). Results drove the design (see [architecture.md](architecture.md#account-constraints-and-how-the-design-adapted)).
3. **Key pair** `shopnow-key` (ED25519) created by CLI, stored only on the laptop.
4. **State bucket** `shopnow-tfstate-926375049914`: versioning, AES256 encryption, public-access block (`evidence/B-state-bucket.txt`).
5. **Bootstrap Terraform** (`infra/bootstrap`, run from the laptop): 3 ECR repos + lifecycle policies, Jenkins IAM role/profile, Jenkins security group, Jenkins EC2 (`c7i-flex.large`, encrypted gp3, IMDSv2). Plan reviewed before apply (11 resources).
6. **Jenkins install** completed after an apt signing-key rotation (verified by fingerprint).

## Configuration reference
| Item | Value |
| --- | --- |
| Region | ap-southeast-2 |
| State | `s3://shopnow-tfstate-926375049914/bootstrap/terraform.tfstate`, `use_lockfile = true` |
| Jenkins EC2 | c7i-flex.large, Ubuntu 24.04, 20 GB gp3 encrypted, 2 GB swap, IMDSv2 required |
| Jenkins SG | 22 from team IPs; 8080 from team IPs + GitHub webhook ranges; 8080/9100 from 10.0.0.0/16 (Prometheus over peering) |
| ECR | `shopnow-frontend`, `shopnow-admin`, `shopnow-backend`; scan on push; keep last 5 |
| Variables | `infra/bootstrap/terraform.tfvars` (git-ignored): `team_cidrs` |

## Troubleshooting
See [09-troubleshooting.md](09-troubleshooting.md): region SCP, Spot SCP, free-tier instance types, EKS extended support, key file CRLF, Jenkins key rotation, wrong AWS profile, changing client IP.

## Evidence
[B-00a](images/B-00a-aws-free-plan-team.png) · [B-00b](images/B-00b-iam-user-kamal-admin.png) · `evidence/B-*.txt`
