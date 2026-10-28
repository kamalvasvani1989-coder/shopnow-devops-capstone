# 02 — Jenkins: server, credentials and pipelines

## Purpose
Jenkins orchestrates everything: infrastructure (Terraform), configuration (Ansible), build/test/deploy (Docker, kubectl) and teardown.

## Prerequisites
Bootstrap complete ([01-bootstrap.md](01-bootstrap.md)); Jenkins reachable from your IP on port 8080.

## Setup steps
1. **Toolchain by Ansible:** `sudo ansible-playbook -i localhost, -c local ansible/jenkins-host.yml` → Docker, AWS CLI, kubectl 1.36, Helm, Terraform, node_exporter; `jenkins` user in `docker` group (`evidence/C-jenkins-host.txt`, `C-jenkins-tools.txt`).
2. **Unlock, admin user, security:** own user database, sign-up off, logged-in users only, anonymous read off.
3. **Plugins:** Git, GitHub, Pipeline, Credentials Binding, Timestamper, Docker Pipeline, Kubernetes CLI, Pipeline: AWS Steps, Ansible, Prometheus metrics, Slack Notification, Workspace Cleanup, Pipeline: Stage View (`evidence/C-jenkins-plugins.txt`).
4. **Credentials** (IDs used by the Jenkinsfiles):

   | ID | Kind | Used by |
   | --- | --- | --- |
   | `github-pat` | Username + fine-grained token (this repo: contents read, webhooks RW) | SCM checkout in all jobs |
   | `ec2-ssh-key` | SSH private key, user `ubuntu` | Ansible → tools EC2 |
   | `mongodb-uri` | Secret text | Kubernetes Secret `mongo` |
   | `slack-webhook` | Secret text | Alertmanager → #shopnow-alerts |
   | `slack-bot-token` | Secret text (`chat:write`) | `slackSend` → #shopnow-builds |
   | `grafana-admin` | Secret text | Grafana admin password |

   No AWS keys: Jenkins uses its EC2 instance role.
5. **Slack:** Manage Jenkins → System → Slack (workspace, `slack-bot-token`, `#shopnow-builds`, custom bot user) — Test Connection: Success.
6. **Jobs** (all "Pipeline script from SCM", branch `*/main`, credential `github-pat`):

   | Job | Script | Trigger | Does |
   | --- | --- | --- | --- |
   | `01-infra-terraform` | `jenkins/Jenkinsfile.infra` | manual (ACTION, ENV, AUTO_APPROVE) | fmt/validate, plan, approval, apply/destroy; on apply success → `02` |
   | `02-config-ansible` | `jenkins/Jenkinsfile.config` | after `01` apply | kubeconfig, syntax check, `site.yml`, infra check; → `03` (DEPLOY_ONLY) |
   | `03-shopnow-cicd` | `Jenkinsfile` | GitHub push; `02` | tests, build, scan, push ECR, deploy, smoke test, rollback on failure, Slack |
   | `99-nightly-destroy` | `jenkins/Jenkinsfile.destroy` | cron 21:00 IST | destroy platform if present, then stop Jenkins itself |

## Webhook
GitHub webhook `http://<jenkins-ip>:8080/github-webhook/` (push events, JSON). Jenkins gets a new public IP on every start (no Elastic IP, by choice), so after each start:
```bash
gh api -X PATCH repos/kamalvasvani1989-coder/shopnow-devops-capstone/hooks/$HOOK_ID/config \
  -f url="http://<new-ip>:8080/github-webhook/" -f content_type=json
gh api -X POST repos/kamalvasvani1989-coder/shopnow-devops-capstone/hooks/$HOOK_ID/pings
```
Also update Manage Jenkins → System → Jenkins URL.

## Pipeline behaviour worth knowing
- Image tag `<git-sha>-<build>`; a push while the cluster is down still builds and pushes (result UNSTABLE, deploy skipped).
- Deploy uses `rollout status --timeout=180s`; on failure the post block runs `rollout undo` for all deployments and posts a red Slack message.
- App changes go through `03`; platform changes (monitoring, add-ons, secrets) go through `02`.

## Evidence
[C-00](images/C-00-jenkins-dashboard.png) · [C-02](images/C-02-jenkins-security.png) · [C-03](images/C-03-jenkins-credentials.png) · [C-04](images/C-04-jenkins-slack-config.png) · [C-09](images/C-09-job-03-config.png) · [C-10](images/C-10-first-build-unstable.png) · [D-04](images/D-04-job-99-config.png) · [E-06](images/E-06-jenkins-dashboard.png) · [E-07](images/E-07-nightly-destroy-success.png)
