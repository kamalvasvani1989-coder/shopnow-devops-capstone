# 07 — Test cases and results

All tests were executed on the real platform. Result: **14 / 14 passed.**

| ID | Area | Test | Expected | Date | Result | Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| T01 | App | Unit tests in every pipeline run (frontend, admin, backend in parallel containers) | Stage green; failure stops the pipeline | 22–27 Oct | ✅ Pass | [C-10](images/C-10-first-build-unstable.png), [E-03](images/E-03-cicd-deploy-success.png) |
| T02 | App | Smoke test after each deploy (`tests/smoke.sh`: `/health`, `/api/health`, `/api/products`, HTML) | All return 200 | 26–27 Oct | ✅ Pass | [evidence/F-invoice-fix-pipeline.txt](evidence/F-invoice-fix-pipeline.txt) |
| T03 | App | Order lifecycle: order placed in storefront, marked Ready in admin | Order visible; status Pending → Ready | 27 Oct | ✅ Pass | [H-01](images/H-01-admin-orders.png), [H-02](images/H-02-admin-order-ready.png) |
| T04 | Deploy | Code change delivered by pipeline (invoice HTML → PDF, `54a4068`) | Live without manual steps | 26 Oct | ✅ Pass (≈ 4 min) | [F-01](images/F-01-before-invoice-html.png), [F-02](images/F-02-pipeline-invoice-fix.png), [F-02c](images/F-02c-invoice-pdf.png) |
| T05 | Deploy | Broken release (readiness `/api/broken`, `4cf934c`) | Rollout fails, automatic undo, no downtime, Slack alert | 26 Oct | ✅ Pass (all checks HTTP 200) | [F-06a](images/F-06a-failed-build.png), [F-06b](images/F-06b-rollback-console.png), [F-06c](images/F-06c-uptime-200.png), [F-07](images/F-07-slack-failure.png), [F-08](images/F-08-rollback-then-fix.png) |
| T06 | Resilience | Delete all backend pods | Replaced and Ready < 1 min | 26 Oct | ✅ Pass (11 s) | [F-03a](images/F-03a-self-heal-delete.png), [F-03b](images/F-03b-self-heal-watch.png) |
| T07 | Scaling | Load test (6 parallel request loops) | HPA scales out, then back in | 26 Oct | ✅ Pass (2 → 4 → 2) | [F-04a](images/F-04a-hpa-scale-up.png), [F-05](images/F-05-hpa-scale-down.png), `evidence/F-hpa-events.txt` |
| T08 | Infra | `apply` on empty state via Jenkins | Platform created; infra check passes | 26 Oct | ✅ Pass | [D-07](images/D-07-apply-success.png), [E-02](images/E-02-config-ansible-success.png) |
| T09 | Infra | Plan after apply (drift check) | "No changes" | 26 Oct | ✅ Pass | [evidence/D-apply-no-changes-no-drift.txt](evidence/D-apply-no-changes-no-drift.txt) |
| T10 | Infra | Destroy, then rebuild from code | Same platform, no manual steps | 26–27 Oct | ✅ Pass (53 resources, ≈ 18 min to running app) | [E-07](images/E-07-nightly-destroy-success.png), [D-08](images/D-08-t10-rebuild-terraform.png)–[D-10](images/D-10-t10-rebuild-deploy.png) |
| T11 | Config | Run `site.yml` twice | Second run makes no changes on servers | 27 Oct | ✅ Pass (tools EC2 `changed=0`) | [evidence/E-config-run-idempotent.txt](evidence/E-config-run-idempotent.txt) |
| T12 | Monitoring | All Prometheus targets | UP | 27 Oct | ✅ Pass (after SG fix) | [G-01a–f](images/G-01f-target-tools-ec2-fixed.png) |
| T13 | Alerting | Scale backend to 0, then restore | Slack FIRING then RESOLVED | 27 Oct | ✅ Pass (21:00 / 21:05) | [G-04](images/G-04-alert-firing.png), [G-06](images/G-06-slack-alerts-fire-resolve.png) |
| T14 | Cost | Guardrails active; nothing billable left after teardown | Budget configured; end-of-session check empty | 21–27 Oct | ✅ Pass | `evidence/B-budgets.txt`, `evidence/E-teardown-day2.txt` |

## Additional automated checks
`tests/infra_check.sh` runs at the end of every Ansible job: cluster ACTIVE, nodes Ready, coredns, metrics-server, monitoring pods, state-bucket versioning, **no NAT gateway**, **≤ 1 load balancer** (cost guards) — 8/8 PASS on every run.
