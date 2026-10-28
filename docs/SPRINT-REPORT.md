# Sprint Report — execution against the project brief

This report follows the six sprints of the brief task by task. Each task links to the implementation and to the evidence (screenshots in [images/](images/), command and console outputs in [evidence/](evidence/)). Dates are the real execution dates.

## Execution timeline

| Date (2026) | Work session | Sprints |
| --- | --- | --- |
| Wed 21 Oct | Repository, account guardrails, budgets, remote state, bootstrap (Jenkins, ECR, IAM); free-plan constraints discovered and adopted | 1, 2 |
| Thu 22 Oct | Jenkins configured with Ansible, plugins, credentials, Slack, MongoDB Atlas; first pipeline run to ECR; GitHub webhook; Terraform jobs created; dev and prod plans | 1, 2, 3 |
| Mon 26 Oct | Platform applied through Jenkins; Ansible chained automatically; application deployed; Sprint 4 tests (code change to production, health checks, self-healing, autoscaling, rollback); nightly destroy | 2, 3, 4 |
| Tue 27 Oct | Full rebuild from code (T10); monitoring and alerting (Sprint 5); final tests; documentation | 5, 6 |

Platform was only running while working: about 2 hours on 26 Oct and 2 hours on 27 Oct.

---

## Sprint 1 — Architecture design, Dockerisation and Jenkins setup

| Brief task | What was done | Evidence |
| --- | --- | --- |
| Design the application architecture for AWS EKS | Two-layer design (persistent / disposable), one load balancer, external database, monitoring in-cluster | [architecture.md](architecture.md) |
| Dockerize the app; store images in ECR | Fixed the original Dockerfiles (Node 20, nginx 1.27, root path build args, admin `/api` proxy); multi-stage images 21 MB / 21 MB / 62 MB; three ECR repositories with lifecycle policy (keep 5) | [A-03-app-changes](images/A-03-app-changes.png), [C-06-ecr-images](images/C-06-ecr-images.png) |
| Jenkins server on EC2 with plugins (Docker, Kubernetes, AWS CLI) | EC2 created by Terraform (`infra/bootstrap`); toolchain installed by Ansible (`jenkins-host.yml`, 18 changes, 0 failures); plugins Docker Pipeline, Kubernetes CLI, Pipeline: AWS Steps, Ansible, Prometheus, Slack, Stage View | [C-00](images/C-00-jenkins-dashboard.png), [C-01](images/C-01-jenkins-plugins.png), [C-02](images/C-02-jenkins-security.png) |
| Jenkins access to EKS/AWS via credentials and IAM roles | AWS access only through the EC2 **instance role** (no access keys in Jenkins); EKS access entries for the Jenkins role and the admin user; six Jenkins credentials (GitHub, SSH, MongoDB, Slack ×2, Grafana) | [C-03](images/C-03-jenkins-credentials.png), [B-00b](images/B-00b-iam-user-kamal-admin.png) |
| Git integration triggers builds on code changes | GitHub webhook → `03-shopnow-cicd`; verified "Started by GitHub push", delivery status 200 | [C-09](images/C-09-job-03-config.png), [C-10](images/C-10-first-build-unstable.png) |

**Goal met:** architecture defined, application containerised and stored in ECR, Jenkins operational with Git-triggered builds.

## Sprint 2 — AWS infrastructure provisioning with Terraform and Jenkins

| Brief task | What was done | Evidence |
| --- | --- | --- |
| Terraform for VPC, EKS, subnets, security groups, EC2 | `infra/platform`: VPC (2 public subnets, no NAT), EKS 1.36 with managed node group and add-ons, security groups, tools EC2, VPC peering, Grafana Pod Identity — 53 resources | `infra/platform/*.tf`, [D-07](images/D-07-apply-success.png) |
| Jenkins job automating Terraform | `01-infra-terraform` (plan / apply / destroy, approval gate, prod guard) | [D-05-approve-stage](images/D-05-approve-stage.png) |
| Consistent provisioning across environments | One codebase, Terraform **workspaces** dev/prod with separate state and tfvars: both plan **52 to add**; prod is plan-only by design (budget) | `docs/evidence/D-plan-dev.txt`, `D-plan-prod.txt` |
| Terraform state in S3 for multi-user access | Bucket with versioning, encryption, public-access block and S3-native lock files | `docs/evidence/B-state-bucket.txt` |

Reproducibility: a re-plan after apply reported **"No changes"** ([D-apply-no-changes-no-drift.txt](evidence/D-apply-no-changes-no-drift.txt)); the platform was destroyed and rebuilt from code (T10, [D-08](images/D-08-t10-rebuild-terraform.png)).

## Sprint 3 — Configuration management with Ansible and Jenkins

| Brief task | What was done | Evidence |
| --- | --- | --- |
| Playbooks to configure EC2, install Docker, kubectl and dependencies | Roles `common` (hardening, updates), `docker`, `cli_tools`, `node_exporter`, `k8s_addons`; dynamic AWS inventory by tag | `ansible/` |
| Jenkins pipeline job running the playbooks | `02-config-ansible` with SSH key and secrets injected from Jenkins credentials | [E-02](images/E-02-config-ansible-success.png) |
| Ansible job triggered after Terraform completes | `01` triggers `02` on a successful apply; `02` triggers the app deploy | [E-01](images/E-01-config-ansible-auto-started.png), [D-09](images/D-09-t10-rebuild-ansible.png) |
| Playbooks tested on Terraform-built infrastructure | Infra check stage (8 PASS); idempotency: second run **changed=0** on the tools EC2 | [E-config-run-idempotent.txt](evidence/E-config-run-idempotent.txt) |

EKS managed nodes are immutable, so "configure Kubernetes nodes" is done through the Kubernetes API (namespaces, secrets, DaemonSets, Helm add-ons) rather than SSH.

## Sprint 4 — CI/CD pipeline for application deployment on EKS

| Brief task | What was done | Evidence |
| --- | --- | --- |
| Multi-stage pipeline: build, test, deploy | `03-shopnow-cicd`: checkout → unit tests (parallel) → build → scan → push to ECR → deploy → smoke test → notify | [E-03](images/E-03-cicd-deploy-success.png) |
| Build image, push to ECR | Tag `<commit>-<build>` links every pod to its commit (e.g. `54a4068-8`) | `docs/evidence/F-images.txt` |
| Kubernetes manifests (Deployment, Service) deployed by Jenkins | `k8s/*.yaml` applied by the pipeline; storefront live through the load balancer | [E-05-storefront](images/E-05-storefront.png) |
| Health checks and auto-scaling | Readiness + liveness probes; HPA on CPU (backend 2–5, frontend 2–4); metrics-server | `docs/evidence/F-probes.txt`, [F-04a](images/F-04a-hpa-scale-up.png), [F-05](images/F-05-hpa-scale-down.png) |
| End-to-end test from code push to EKS | Real defect fixed through the pipeline (invoice HTML → PDF), commit to production ≈ 4 min | [F-01](images/F-01-before-invoice-html.png), [F-02](images/F-02-pipeline-invoice-fix.png), [F-02c](images/F-02c-invoice-pdf.png) |

Resilience: self-healing in 11 s ([F-03b](images/F-03b-self-heal-watch.png)); broken release detected and rolled back with zero downtime ([F-06a](images/F-06a-failed-build.png), [F-06c](images/F-06c-uptime-200.png), [F-08](images/F-08-rollback-then-fix.png)).

## Sprint 5 — Monitoring with Prometheus, Grafana and Jenkins alerts

| Brief task | What was done | Evidence |
| --- | --- | --- |
| Prometheus in EKS collecting app and node metrics | kube-prometheus-stack (Helm via Ansible); targets: backend `/metrics`, node-exporter, kube-state-metrics, both EC2 hosts | [G-01a…f](images/G-01b-target-backend.png) |
| Grafana dashboards for app performance and resource health | ShopNow dashboard (requests/s, p95 latency, 5xx ratio, HPA replicas, pod CPU/memory) + Kubernetes cluster resources | [G-02](images/G-02-grafana-shopnow.png), [G-03a](images/G-03a-grafana-cluster.png) |
| Integrate Jenkins with Prometheus/Grafana | Jenkins Prometheus plugin scraped over VPC peering (target UP); Jenkins host metrics via node_exporter | [G-01d](images/G-01d-target-jenkins.png) |
| Alert rules + Jenkins notifications | PrometheusRule (BackendDown, HighErrorRate, NodeHighCPU, NodeLowMemory, JenkinsDown, …) → Alertmanager → Slack; Jenkins posts every build result to Slack | [G-04](images/G-04-alert-firing.png), [G-06](images/G-06-slack-alerts-fire-resolve.png), [F-07](images/F-07-slack-failure.png) |
| Test monitoring and alerting | BackendDown fired 21:00 and resolved 21:05; a real `TargetDown` alert fired for an unreachable exporter and resolved after the fix | [G-06](images/G-06-slack-alerts-fire-resolve.png), [G-01e](images/G-01e-target-tools-ec2-down.png) → [G-01f](images/G-01f-target-tools-ec2-fixed.png) |

## Sprint 6 — Testing, documentation and final automation

| Brief task | What was done | Evidence |
| --- | --- | --- |
| Test cases for application, deployment and infrastructure | 14 test cases, all passed | [07-testing.md](07-testing.md) |
| Documentation including configuration and troubleshooting | Chapters 01–09, architecture, this report, 25 troubleshooting entries from real issues | [docs/](.) |
| Automated triggers for each stage | push → build → deploy (webhook); apply → configure → deploy (job chaining); nightly destroy (cron 21:00 IST) | [E-07](images/E-07-nightly-destroy-success.png) |
| Final end-to-end testing | Full rebuild from code in ≈ 18 min, then all Sprint 5 tests on the rebuilt platform | [D-08…D-10](images/D-10-t10-rebuild-deploy.png) |
| Feedback and adjustments for production readiness | Fixes applied during testing: tools EC2 SG rule, Grafana memory, IRSA → Pod Identity, invoice PDF; recommendations in [09-troubleshooting.md](09-troubleshooting.md) and [architecture.md](architecture.md) | |
