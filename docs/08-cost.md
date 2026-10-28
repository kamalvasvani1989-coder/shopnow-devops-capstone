# 08 — Cost optimisation and actual spend

**Budget:** USD 30. **Goal:** a design that is cheap to build *and* cheap to keep, since the project must remain available until evaluation.

## Actual daily cost (Cost Explorer, credits excluded)
| Date | Cost (USD) | What was running |
| --- | --- | --- |
| 21 Oct | 2.95 | Includes the last hours of a previous, unrelated assignment's resources (removed that day) plus this project's bootstrap |
| 22 Oct | 1.10 | Jenkins only (configuration, first builds) |
| 23 Oct | 0.14 | Everything stopped (Jenkins disk, ECR, S3) |
| 24 Oct | 0.14 | Stopped |
| 25 Oct | 0.27 | Stopped (billing lag) |
| 26 Oct | **1.25** | **Full platform ≈ 2 h** (EKS, node, load balancer, tools EC2) + Jenkins, then nightly destroy |
| 27 Oct | see Cost Explorer | Full platform ≈ 2 h (rebuild, monitoring, tests) |
| 28 Oct | see Cost Explorer (≈ 4–5 expected) | Platform left running overnight ≈ 12 h because the safety net was disabled (troubleshooting #25); destroyed in the morning |

Source: [evidence/H-cost-daily.txt](evidence/H-cost-daily.txt). Baseline before the project: `evidence/B-cost-before-capstone.txt` — the previous assignment's month showed load balancers (7.94) and VPC/IPv4 (5.87) costing almost as much as EKS (13.52). That lesson shaped this design.

**Headline:** a full working day of the platform ≈ **USD 1.25**; an idle day ≈ **USD 0.14**. Total project spend: a few dollars of the USD 30 budget.

## Decisions that saved money
| Decision | Saving |
| --- | --- |
| Destroy the platform nightly (job `99-nightly-destroy`, 21:00 IST) and rebuild in ≈ 18 min from code | Idle cost ≈ USD 9/day → ≈ 0.14/day |
| Stop Jenkins when idle; no Elastic IP (webhook updated on start instead) | No compute or idle-IP charges while stopped |
| No NAT gateway | ≈ USD 1/day + data processing |
| One load balancer; internal tools via port-forward | ≈ USD 0.60/day per avoided LB |
| One worker node sized to fit the measured pod budget | Half the node cost of a 2-node design |
| EKS 1.36 (standard support) instead of 1.33 (extended) | Control plane USD 0.10/h instead of 0.60/h |
| MongoDB Atlas M0 | Free database that survives rebuilds |
| ECR lifecycle (keep 5) + multi-stage images (≈ 104 MB total) | ≈ USD 0.01/month storage |
| Prometheus without persistent volume | No EBS / CSI driver |
| Cost guards in `infra_check.sh` (fail if a NAT gateway or > 1 LB exists) | Prevents expensive drift |

## Guardrails
- Daily cost budget `capstone-daily-7usd` (email at 80 %) and AWS Cost Anomaly Detection.
- `scripts/session-end-check.sh` after every session: no cluster, no LBs, no NAT, no loose volumes or Elastic IPs (`evidence/E-teardown-day2.txt`).
- Free-plan credits act as a hard cap; no charges beyond them.

## Cost visibility note
The Grafana dashboard includes an AWS EstimatedCharges panel, but the Free plan account publishes no CloudWatch billing metric, so the panel shows "No data". Cost monitoring therefore uses Cost Explorer and the budget alert.
