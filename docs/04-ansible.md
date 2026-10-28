# 04 — Ansible: configuration management

## Purpose
Configure servers and the cluster from code, idempotently, as a Jenkins job chained after Terraform.

## Prerequisites
Collections `amazon.aws`, `kubernetes.core`, `community.general` for the `jenkins` user (installed by `jenkins-host.yml`); credentials `ec2-ssh-key`, `mongodb-uri`, `grafana-admin`, `slack-webhook`.

## Playbooks
| Playbook | Targets | Run by |
| --- | --- | --- |
| `jenkins-host.yml` | the Jenkins EC2 itself (`-i localhost, -c local`) | once, over SSH (Sprint 1) |
| `site.yml` play 1 | tools EC2, found by **dynamic inventory** (`inventory/aws_ec2.yml`, tags `Project=shopnow`, `Role=tools`), reached over VPC peering | `02-config-ansible` |
| `site.yml` play 2 | EKS cluster via the Kubernetes API (`connection: local`) | `02-config-ansible` |

## Roles
| Role | Does |
| --- | --- |
| `common` | security updates, unattended-upgrades, timezone, SSH password login disabled |
| `docker` | Docker engine, users in `docker` group |
| `cli_tools` | AWS CLI v2, kubectl matching the cluster minor; on Jenkins also Helm and Terraform |
| `node_exporter` | node_exporter 1.9.1 as a systemd service on :9100 |
| `k8s_addons` | namespaces, `mongo` Secret, metrics-server, Grafana dashboards (ConfigMaps), kube-prometheus-stack (rendered values incl. Slack webhook, then deleted), PrometheusRule |

EKS managed nodes are immutable (replaced, not patched), so they are configured through the Kubernetes API — namespaces, secrets, DaemonSets and Helm releases — not over SSH.

## Results
- First run on the new cluster: success; **infra check 8/8 PASS** (cluster ACTIVE, nodes Ready, coredns, metrics-server, monitoring pods, state versioning, no NAT, ≤ 1 load balancer).
- **Idempotency (T11):** second run → tools EC2 `ok=17 changed=0`; duration 1 m 01 s vs 3 m 10 s ([evidence/E-config-run-idempotent.txt](evidence/E-config-run-idempotent.txt)). `localhost changed=3` is the rendered values file (create + delete) and Helm reporting an upgrade without the diff plugin.

## Evidence
[E-01](images/E-01-config-ansible-auto-started.png) · [E-02](images/E-02-config-ansible-success.png) · [D-09](images/D-09-t10-rebuild-ansible.png) · `evidence/C-jenkins-host.txt`
