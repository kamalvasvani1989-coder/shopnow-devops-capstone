# 05 — Application on Kubernetes (EKS)

## Purpose
Run ShopNow on EKS so it is scalable, self-healing and safely updatable, deployed only by the pipeline.

## Application changes made to the original repository
| File | Change | Reason |
| --- | --- | --- |
| `frontend/Dockerfile`, `admin/Dockerfile` | node:20 / nginx:1.27; `PUBLIC_URL=/`, `REACT_APP_API_BASE_URL=/api` | original built for a `/aryan` path prefix; empty value produced `//api`; node 18 end-of-life |
| `admin/nginx/default.conf` | added `location /api/` proxy | admin app calls `/api/...` |
| `backend/Dockerfile` | node:20, `npm ci --omit=dev`, non-root user, healthcheck on `/api/health` | deprecated flag, hardening |
| `backend/server.js` | `express-prom-bundle` → `/metrics` | request rate, status codes, latency for Prometheus |
| `frontend/src/App.js` | invoice generated as **PDF** (html2pdf.js) | defect found in testing: invoice downloaded as `.html` |

## Kubernetes objects (`k8s/`)
| Object | Settings |
| --- | --- |
| Deployments frontend / backend / admin | RollingUpdate `maxUnavailable: 0`, `maxSurge: 1`; requests/limits on every container; image `__REGISTRY__/shopnow-<svc>:__TAG__` replaced by the pipeline |
| Probes | backend readiness `/api/health` (5 s, every 10 s), liveness (20 s, every 15 s, 3 failures); frontend/admin `/health` |
| Services | `frontend` type LoadBalancer (only public entry); `backend-service` and `admin` ClusterIP |
| HPA | backend 2–5, frontend 2–4, target CPU 60 % of request |
| ServiceMonitor | backend `/metrics` every 30 s |
| Secret `mongo` | created by Ansible from Jenkins credential, never in Git |

Access to internal tools: `kubectl -n shopnow port-forward svc/admin 8082:80`, Grafana `svc/kps-grafana 3000:80`, Prometheus `svc/kps-kube-prometheus-stack-prometheus 9090:9090`.

## Results
| Test | Result |
| --- | --- |
| Storefront live through the load balancer; 6 products seeded; orders placed | ✅ [E-05](images/E-05-storefront.png) |
| Code change to production (invoice fix, commit `54a4068`) | ✅ ≈ 4 min, all stages green; PDF verified ([F-02](images/F-02-pipeline-invoice-fix.png), [F-02c](images/F-02c-invoice-pdf.png)) |
| Traceability | all three Deployments ran `54a4068-8` = `git log` head (`evidence/F-images.txt`) |
| Self-healing | both backend pods deleted → replacements Ready in 11 s ([F-03b](images/F-03b-self-heal-watch.png)) |
| Autoscaling | CPU 6 % → 114 % under load → 4 replicas → settled at 53–60 %; back to 2 after the 5-min stabilisation window (`evidence/F-hpa-events.txt`) |
| Broken release | readiness path broken on purpose (`4cf934c`): rollout timed out, automatic `rollout undo`, red Slack message, **all uptime checks HTTP 200**; fixed with `git revert` ([F-06a–d](images/F-06a-failed-build.png), [F-08](images/F-08-rollback-then-fix.png)) |
| Order lifecycle (admin) | order placed in storefront, marked Ready in admin ([H-01](images/H-01-admin-orders.png), [H-02](images/H-02-admin-order-ready.png)) |
