# Evidence index

Screenshots in `images/` (personal data blurred), console and command outputs in `evidence/`. Letters follow the work blocks: A repo · B account/bootstrap · C Jenkins (Sprint 1) · D Terraform (Sprint 2) · E Ansible/deploy (Sprints 3–4) · F application tests (Sprint 4) · G monitoring (Sprint 5) · H final tests (Sprint 6).

| File | Shows |
| --- | --- |
| [A-01-repo-structure.png](images/A-01-repo-structure.png) | GitHub fork with all project folders |
| [A-02-clone-and-identity.png](images/A-02-clone-and-identity.png) | Clone + per-repo Git identity (personal noreply) |
| [A-03-app-changes.png](images/A-03-app-changes.png) | Changes made to the original app (diff stat) |
| [B-00a-aws-free-plan-team.png](images/B-00a-aws-free-plan-team.png) | AWS Free-plan settings (project owner) |
| [B-00b-iam-user-kamal-admin.png](images/B-00b-iam-user-kamal-admin.png) | IAM user kamal-admin (AdministratorAccess, CLI only) |
| [C-00-jenkins-dashboard.png](images/C-00-jenkins-dashboard.png) | Jenkins first dashboard |
| [C-01-jenkins-plugins.png](images/C-01-jenkins-plugins.png) | Required Jenkins plugins with versions |
| [C-02-jenkins-security.png](images/C-02-jenkins-security.png) | Jenkins security settings |
| [C-03-jenkins-credentials.png](images/C-03-jenkins-credentials.png) | Six Jenkins credentials (values hidden) |
| [C-04-jenkins-slack-config.png](images/C-04-jenkins-slack-config.png) | Jenkins Slack config: Test Connection success |
| [C-05-slack-webhook-test.png](images/C-05-slack-webhook-test.png) | Slack incoming webhook test |
| [C-05b-slack-channels.png](images/C-05b-slack-channels.png) | Slack channels |
| [C-06-ecr-images.png](images/C-06-ecr-images.png) | Three images in ECR (tag 2cfa19b-1) |
| [C-07-atlas-cluster.png](images/C-07-atlas-cluster.png) | MongoDB Atlas M0, AWS Sydney |
| [C-08-atlas-ping.png](images/C-08-atlas-ping.png) | Atlas reachable from Jenkins ({ ok: 1 }) |
| [C-09-job-03-config.png](images/C-09-job-03-config.png) | Job 03 SCM configuration |
| [C-10-first-build-unstable.png](images/C-10-first-build-unstable.png) | First pipeline run (UNSTABLE: cluster down, images pushed) |
| [D-04-job-99-config.png](images/D-04-job-99-config.png) | Job 99 configuration |
| [D-05-approve-stage.png](images/D-05-approve-stage.png) | Terraform approval gate |
| [D-06-apply-irsa-denied.png](images/D-06-apply-irsa-denied.png) | First apply: OIDC provider denied by SCP |
| [D-07-apply-success.png](images/D-07-apply-success.png) | Apply success after enable_irsa=false |
| [D-08-t10-rebuild-terraform.png](images/D-08-t10-rebuild-terraform.png) | T10 rebuild: Terraform apply |
| [D-09-t10-rebuild-ansible.png](images/D-09-t10-rebuild-ansible.png) | T10 rebuild: Ansible auto-triggered |
| [D-10-t10-rebuild-deploy.png](images/D-10-t10-rebuild-deploy.png) | T10 rebuild: deploy auto-triggered |
| [E-01-config-ansible-auto-started.png](images/E-01-config-ansible-auto-started.png) | Ansible job started automatically after apply |
| [E-02-config-ansible-success.png](images/E-02-config-ansible-success.png) | Ansible job success incl. infra check |
| [E-03-cicd-deploy-success.png](images/E-03-cicd-deploy-success.png) | Deploy + smoke test success |
| [E-04-pods-running.png](images/E-04-pods-running.png) | All pods running |
| [E-05-storefront.png](images/E-05-storefront.png) | Storefront live via load balancer |
| [E-06-jenkins-dashboard.png](images/E-06-jenkins-dashboard.png) | Jenkins dashboard, all jobs green |
| [E-07-nightly-destroy-success.png](images/E-07-nightly-destroy-success.png) | Nightly destroy: platform destroyed, Jenkins stopped |
| [F-01-before-invoice-html.png](images/F-01-before-invoice-html.png) | Before: invoice downloaded as HTML (personal data blurred) |
| [F-02-pipeline-invoice-fix.png](images/F-02-pipeline-invoice-fix.png) | Invoice fix through pipeline, all stages green |
| [F-02b-invoice-pdf-download.png](images/F-02b-invoice-pdf-download.png) | After: invoice downloaded as PDF |
| [F-02c-invoice-pdf.png](images/F-02c-invoice-pdf.png) | PDF invoice opened |
| [F-03a-self-heal-delete.png](images/F-03a-self-heal-delete.png) | Self-heal: backend pods deleted |
| [F-03b-self-heal-watch.png](images/F-03b-self-heal-watch.png) | Self-heal: replacements Ready in 11 s |
| [F-04a-hpa-scale-up.png](images/F-04a-hpa-scale-up.png) | HPA scale-out 2 -> 4 at 114 % CPU |
| [F-04b-hpa-load-stopped.png](images/F-04b-hpa-load-stopped.png) | Load stopped, CPU drops |
| [F-05-hpa-scale-down.png](images/F-05-hpa-scale-down.png) | HPA scale-in back to 2 |
| [F-06a-failed-build.png](images/F-06a-failed-build.png) | Broken release: deploy failed (build #11) |
| [F-06b-rollback-console.png](images/F-06b-rollback-console.png) | Automatic rollout undo in console |
| [F-06c-uptime-200.png](images/F-06c-uptime-200.png) | Uptime during rollback: all HTTP 200 |
| [F-06d-rollback-pods.png](images/F-06d-rollback-pods.png) | Broken pod 0/1 while old pods serve |
| [F-07-slack-failure.png](images/F-07-slack-failure.png) | Slack: FAILED, rolled back |
| [F-08-rollback-then-fix.png](images/F-08-rollback-then-fix.png) | #11 red then #12 green after git revert |
| [G-01a-target-node-exporter.png](images/G-01a-target-node-exporter.png) | Target: EKS node-exporter UP |
| [G-01b-target-backend.png](images/G-01b-target-backend.png) | Target: backend /metrics UP |
| [G-01c-target-kube-state-metrics.png](images/G-01c-target-kube-state-metrics.png) | Target: kube-state-metrics UP |
| [G-01d-target-jenkins.png](images/G-01d-target-jenkins.png) | Target: Jenkins UP (VPC peering) |
| [G-01e-target-tools-ec2-down.png](images/G-01e-target-tools-ec2-down.png) | Target: tools EC2 DOWN (SG bug) |
| [G-01f-target-tools-ec2-fixed.png](images/G-01f-target-tools-ec2-fixed.png) | Target: tools EC2 UP after fix |
| [G-02-grafana-shopnow.png](images/G-02-grafana-shopnow.png) | Grafana ShopNow dashboard under load |
| [G-03a-grafana-cluster.png](images/G-03a-grafana-cluster.png) | Grafana cluster resources: CPU/memory |
| [G-03b-grafana-network.png](images/G-03b-grafana-network.png) | Grafana cluster resources: network |
| [G-03c-grafana-storage.png](images/G-03c-grafana-storage.png) | Grafana cluster resources: storage |
| [G-04-alert-firing.png](images/G-04-alert-firing.png) | Prometheus: BackendDown firing |
| [G-05-watchdog.png](images/G-05-watchdog.png) | Watchdog (always firing by design) |
| [G-06-slack-alerts-fire-resolve.png](images/G-06-slack-alerts-fire-resolve.png) | Slack: TargetDown and BackendDown fired and resolved |
| [H-01-admin-orders.png](images/H-01-admin-orders.png) | Admin dashboard with orders (personal data blurred) |
| [H-02-admin-order-ready.png](images/H-02-admin-order-ready.png) | Admin: test order marked Ready |

## Console / command outputs added in the final bundle

| File | Shows |
| --- | --- |
| [D-apply-no-changes-no-drift.txt](evidence/D-apply-no-changes-no-drift.txt) | Re-apply: "No changes" (no drift) |
| [D-t10-rebuild-apply.txt](evidence/D-t10-rebuild-apply.txt) | T10 rebuild: 53 resources added |
| [E-config-run-idempotent.txt](evidence/E-config-run-idempotent.txt) | Ansible second run: changed=0 on tools EC2; infra check 8/8 |
| [F-invoice-fix-pipeline.txt](evidence/F-invoice-fix-pipeline.txt) | Pipeline delivering the invoice fix (54a4068-8) |
| [F-deploy-rollback.txt](evidence/F-deploy-rollback.txt) | Failed release and automatic rollback (4cf934c-11) |

Other `evidence/*.txt` files were saved by `tee` during execution and are already in the repository.
