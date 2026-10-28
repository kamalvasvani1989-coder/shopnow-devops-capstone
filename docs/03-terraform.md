# 03 — Terraform: the platform (disposable layer)

## Purpose
Provision the complete AWS environment for the application reproducibly, from Jenkins, with shared remote state.

## Prerequisites
Bootstrap done; Jenkins role has permissions; state bucket exists; `infra/platform/envs/dev.tfvars` lists the IAM principals for kubectl access.

## Setup steps
1. Jenkins → `01-infra-terraform` → Build with Parameters → `plan` / `dev` (free) — review the plan.
2. `apply` / `dev` — the Approve stage pauses for review unless AUTO_APPROVE is ticked.
3. On success the pipeline archives `tf-outputs.json` and starts `02-config-ansible`.
4. Teardown: `destroy` (pre-destroy step deletes Kubernetes load balancers first), or the nightly job.

## What gets created (53 resources)
| Area | Resources |
| --- | --- |
| Network | VPC 10.0.0.0/16, 2 public subnets (ap-southeast-2a/b), IGW, route table, **no NAT**, VPC peering to the default VPC + routes both ways |
| EKS | Cluster `shopnow-dev` 1.36, API auth mode, access entries (Jenkins role, `kamal-admin`), add-ons vpc-cni, coredns, kube-proxy, eks-pod-identity-agent; logging off; no KMS key; **IRSA off** |
| Nodes | Managed node group: 1 × m7i-flex.large On-Demand (min 1, max 2), 20 GB |
| Tools EC2 | t3.micro Ubuntu 24.04; SSH only from the default VPC (Jenkins); 9100 from the project VPC |
| Grafana access | IAM role + **EKS Pod Identity association** (`monitoring/kps-grafana`) with CloudWatch read-only |

## Configuration reference
| File | Key settings |
| --- | --- |
| `versions.tf` | S3 backend `platform/terraform.tfstate`, `use_lockfile = true`, AWS provider ~> 5.95 |
| `variables.tf` | `region = ap-southeast-2`, `cluster_version = 1.36`, `node_capacity = ON_DEMAND`, `node_instance_types = [m7i-flex.large]`, `node_desired = 1` |
| `envs/dev.tfvars` | env, capacity, desired size, `admin_principal_arns` |
| `envs/prod.tfvars` | prod values (10.1.0.0/16) — **plan only**, the job's Guard stage refuses apply |
| `eks.tf` | `enable_irsa = false`, `enable_cluster_creator_admin_permissions = true`, `create_kms_key = false` |

**Environments:** Terraform workspaces `dev` and `prod` keep separate state files in the same bucket (`env:/prod/...`). Both plan 52 resources from the same code.

**State locking:** S3-native lock file (`.tflock`) — a second concurrent run waits/fails instead of corrupting state ("Releasing state lock" appears in every run).

## Results
- First apply: everything except the OIDC provider (SCP denied) → `enable_irsa = false` → re-apply "No changes" ([D-06](images/D-06-apply-irsa-denied.png), [D-07](images/D-07-apply-success.png)).
- **T10 rebuild:** `Apply complete! Resources: 53 added` in 10 m 20 s; whole chain to running app ≈ 18 min ([evidence/D-t10-rebuild-apply.txt](evidence/D-t10-rebuild-apply.txt)).
- **No drift:** re-plan after apply → "No changes. Your infrastructure matches the configuration." ([evidence/D-apply-no-changes-no-drift.txt](evidence/D-apply-no-changes-no-drift.txt)).

## Troubleshooting
OIDC provider denied, tools EC2 security group rule, `tf-outputs.json` missing on plan runs, destroy blocked by load balancers — see [09-troubleshooting.md](09-troubleshooting.md).
