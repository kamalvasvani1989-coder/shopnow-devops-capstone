# 06 — Monitoring and alerting

## Purpose
Real-time visibility into the application, the cluster, Jenkins and the EC2 hosts, with alerts to Slack.

## Components (installed by Ansible via Helm: kube-prometheus-stack)
| Component | Role |
| --- | --- |
| Prometheus | scrapes metrics every 30 s, evaluates alert rules (retention 2 days, no PV) |
| Alertmanager | groups and routes alerts → Slack `#shopnow-alerts` (Watchdog → null receiver) |
| Grafana | dashboards; admin password from Jenkins credential; 512 Mi memory limit |
| node-exporter, kube-state-metrics | node and Kubernetes object metrics |

## Scrape targets (all UP — [G-01a…f](images/G-01f-target-tools-ec2-fixed.png))
| Target | Source |
| --- | --- |
| `serviceMonitor/shopnow/backend` | app `/metrics` (2 pods) |
| `kps-prometheus-node-exporter` | EKS node |
| `kps-kube-state-metrics` | pods, deployments, HPA |
| `jenkins` | `172.31.10.250:8080/prometheus/` over VPC peering |
| `ec2-node-exporter` | Jenkins host + tools EC2 (:9100) |

## Dashboards
- **ShopNow – application, scaling and cost** (`monitoring/dashboards/shopnow.json`, loaded automatically): requests/s, p95 latency, 5xx ratio, HPA replicas, pod CPU and memory ([G-02](images/G-02-grafana-shopnow.png)). The cost panel shows "No data" because the Free plan publishes no billing metric — cost is reported from Cost Explorer ([08-cost.md](08-cost.md)).
- **Kubernetes / Compute Resources / Cluster** (built in): CPU, memory, network and storage per namespace ([G-03a–c](images/G-03a-grafana-cluster.png)).

## Alert rules (`monitoring/alert-rules.yaml`)
BackendDown, HighErrorRate, PodRestartingOften, NodeHighCPU, NodeLowMemory, JenkinsDown, JenkinsBuildFailed — plus the stack's defaults (e.g. TargetDown). **Watchdog** is always firing by design (pipeline heartbeat).

## Notifications
| Source | Channel | Example |
| --- | --- | --- |
| Alertmanager | #shopnow-alerts | `[FIRING] BackendDown` 21:00 → `[RESOLVED]` 21:05 |
| Jenkins `slackSend` | #shopnow-builds | `shopnow 4cf934c-11 FAILED, rolled back` |

## Results
- Planned test (T13): backend scaled to 0 → Firing after 1 min → Slack; restored → Resolved ([G-04](images/G-04-alert-firing.png), [G-06](images/G-06-slack-alerts-fire-resolve.png)).
- Real incident: `TargetDown` fired when the tools EC2 exporter was unreachable (security group rule) and resolved after the fix ([G-01e](images/G-01e-target-tools-ec2-down.png) → [G-01f](images/G-01f-target-tools-ec2-fixed.png)).
