# testing

> Must cover: Test cases T01-T14 with date, result and screenshot
> Owner: <M1-M4 name>   ·   Source material: docs/CAPSTONE-PLAN.pdf

## Purpose

## Prerequisites

## Setup steps

## Configuration reference

## Troubleshooting

## Test log
| ID | Area | Test | Expected | Date | Result | Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| T01 | App | Unit tests in pipeline | Green; failing test turns build red | | | |
| T02 | App | `tests/smoke.sh` vs LB URL | /health, /api/health, /api/products 200 | | | |
| T03 | App | Order in storefront, mark ready in admin | Status changes in admin | | | |
| T04 | Deploy | Push UI text change to main | Live in ~10 min, no manual step | | | |
| T05 | Deploy | Push commit breaking /api/health | Rollout fails, auto undo, site stays up, Slack msg | | | |
| T06 | Resilience | Delete all backend pods | Ready again < 1 min | | | |
| T07 | Scaling | Busybox load test | HPA 2 -> 3+ and back | | | |
| T08 | Infra | Apply on empty state | infra_check.sh passes | | | |
| T09 | Infra | `terraform plan -detailed-exitcode` | Exit 0 (no drift) | | | |
| T10 | Infra | Destroy then apply again | Same result, no leftovers | | | |
| T11 | Config | Run site.yml twice | 2nd run changed=0 (or near) | | | |
| T12 | Monitoring | Prometheus targets | All UP | | | |
| T13 | Alerting | Scale backend to 0 | BackendDown in Slack ~2 min, then resolved | | | |
| T14 | Cost | Budget alert | 33% email / thresholds screenshot | | | |
