# 09 — Troubleshooting (real issues met during this project)

Every entry below happened during the build. Format: symptom → cause → fix.

| # | Area | Symptom | Cause | Fix |
| --- | --- | --- | --- | --- |
| 1 | GitHub | Fork created with a long name; clone "Repository not found" | Fork named differently than expected | `gh repo rename shopnow-devops-capstone -R <owner>/<old-name>` |
| 2 | GitHub | Risk of pushing with the work account | Browser and Credential Manager hold a second (work) GitHub login | `gh auth login` via device code in a private window; `gh auth setup-git`; per-repo `user.name/email` (noreply) |
| 3 | Git | Many unchanged files shown as modified | Original repo stored CRLF; `.gitattributes` normalises to LF | Verified with `git diff --ignore-cr-at-eol --stat`; committed normalisation |
| 4 | AWS | `UnauthorizedOperation … explicit deny in a service control policy` for us-east-1 | Free plan locks the account to one Region | All code switched to `ap-southeast-2` |
| 5 | AWS | Spot dry-run denied by SCP | Free plan denies Spot | `node_capacity = "ON_DEMAND"` |
| 6 | AWS | EKS 1.33 listed as `EXTENDED_SUPPORT` | Extended support costs USD 0.60/h | `cluster_version = "1.36"` |
| 7 | AWS | `InvalidParameterCombination: not eligible for Free Tier` launching t3.medium | Free plan allows only free-tier-eligible types (dry-run does not check this) | Jenkins c7i-flex.large, node m7i-flex.large ×1, tools t3.micro |
| 8 | AWS CLI | `RepositoryNotFoundException … registry 187494036710` | New terminal used the default profile (another account) | `export AWS_PROFILE=capstone`; `.capstone-env` sourced in every terminal |
| 9 | SSH | `Load key …: invalid format` | Key written by AWS CLI on Windows had CRLF endings | `sed -i 's/\r$//' ~/.ssh/shopnow-key.pem` |
| 10 | Jenkins | `NO_PUBKEY 7198F4B714ABFC68`, `jenkins.service does not exist` | Jenkins rotated its apt signing key | Installed `jenkins.io-2026.key`, verified fingerprint, updated user-data |
| 11 | Slack | `"error":"missing_scope"` | Bot token had only `incoming-webhook` | Added `chat:write` under **Bot** Token Scopes, reinstalled app |
| 12 | Jenkins | Job 02 SCM credential set to the SSH key | Both credentials appear in the same dropdown | SCM uses `github-pat`; SSH key only inside `withCredentials` |
| 13 | Network | Jenkins unreachable after changing location | Client public IP changed; SG allows listed IPs only | Added the IP to `team_cidrs`; `terraform apply` (1 in-place change) |
| 14 | Jenkins | Webhook stops triggering after a restart | Jenkins gets a new public IP on every start (no Elastic IP, by choice) | `gh api` PATCH of the hook URL + ping; update Jenkins URL |
| 15 | Terraform | `iam:CreateOpenIDConnectProvider … explicit deny` during EKS apply | SCP denies OIDC providers (needed only for IRSA) | `enable_irsa = false`; Grafana uses EKS Pod Identity; re-apply → no changes |
| 16 | Terraform | `tf-outputs.json doesn't match anything` on plan runs | Outputs only exist after apply | Expected; `allowEmptyArchive: true` |
| 17 | Monitoring | Tools EC2 target DOWN: `context deadline exceeded` | SG allowed 9100 only from the module's node SG, but managed nodes with the default launch template use the EKS **cluster** SG | Rule changed to the project VPC CIDR; `TargetDown` resolved |
| 18 | Monitoring | Grafana port-forward drops: `connection refused` | Grafana container **OOMKilled** at 256 Mi | Limit 512 Mi in Helm values; applied via `02-config-ansible` (platform changes go through Ansible, not the app pipeline) |
| 19 | Kubernetes | HPA events `FailedGetResourceMetric … pods might be unready` | New pods have no CPU samples yet | Transient; resolves after one scrape interval |
| 20 | Kubernetes | Terminated backend pods show status `Error` | Node.js backend has no SIGTERM handler (exits non-zero) | No user impact; improvement: close HTTP server and DB connection on SIGTERM |
| 21 | Kubernetes | `rollout undo` warns about `last-applied-configuration` | Undo restores pods but not the apply annotation | Fix the source with `git revert` and let the pipeline re-apply |
| 22 | Network | Storefront timed out from the laptop once | Transient client-side/DNS issue after a new load balancer | Verified 200 from laptop, from Jenkins and ELB `InService` |
| 23 | Monitoring | Grafana cost panel "No data" | Free plan publishes no CloudWatch billing metric | Cost evidence from Cost Explorer and budget alert |
| 24 | Application | Invoice downloaded as `.html` although the function is `generateInvoicePDF` | Defect in the original app | Rendered with html2pdf.js; delivered through the pipeline (T04) |
| 25 | Cost | Platform still running the next morning | `99-nightly-destroy` was disabled during a session and re-enabled after 21:00; Jenkins cron does not run missed schedules | Ran the job manually next morning (≈ 12 h extra runtime). Lesson: re-enable the safety net before 21:00 or tear down manually at session end |

## Quick diagnostic commands
```bash
source .capstone-env && aws sts get-caller-identity          # right account?
kubectl get nodes; kubectl -n shopnow get pods,hpa,svc        # cluster state
kubectl -n shopnow describe pod -l app=backend | grep -A4 'Last State'
kubectl -n monitoring get pods                                # monitoring stack
bash scripts/session-end-check.sh                             # anything left billing?
```
