# Architecture

```mermaid
flowchart TB
  gh[GitHub fork] -- webhook on push --> jenkins
  subgraph persistent[Persistent layer - kept all project]
    jenkins[Jenkins EC2 t3.medium<br/>Terraform, Ansible, Docker, kubectl, Helm]
    s3[(S3 Terraform state)]
    ecr[(ECR - 3 repos)]
    jenkins --> s3
    jenkins -- push images --> ecr
  end
  subgraph disposable[Disposable layer - project VPC 10.0.0.0/16, rebuilt each session]
    lb[Classic Load Balancer - storefront only]
    subgraph eks[EKS - 2 x t3.medium Spot]
      mon[ns monitoring<br/>Prometheus, Grafana, Alertmanager]
      app[ns shopnow<br/>frontend HPA 2-4, backend HPA 2-5, admin]
    end
    tools[Tools EC2 t3.micro - configured by Ansible]
  end
  jenkins -- terraform / ansible / kubectl --> disposable
  ecr -- pull --> app
  users[Users] --> lb --> app
  app --> atlas[(MongoDB Atlas M0 - free)]
  mon --> slack[Slack]
  persistent <-. VPC peering: SSH + Prometheus scrape .-> disposable
```

## Design decisions (and the production alternative)
| Decision | Saves | Production would use |
| --- | --- | --- |
| No NAT gateway; nodes in public subnets with tight security groups | ~$1.08/day | Private subnets + NAT gateway (or VPC endpoints) |
| One Classic LB for the storefront; admin/Grafana via `kubectl port-forward` | ~$0.60/day per extra LB | AWS Load Balancer Controller + one ALB with path/host rules and TLS |
| Spot worker nodes | ~2/3 of node cost | Mixed on-demand + Spot node groups, Cluster Autoscaler/Karpenter |
| MongoDB Atlas M0 | free; data survives teardown | Atlas dedicated tier / DocumentDB in private subnets with peering |
| Cluster destroyed every night | ~$2.40/day control plane | Long-lived clusters per environment |
| No Prometheus persistence (2-day retention) | EBS + EBS CSI driver | Amazon Managed Prometheus or persistent volumes |
| Jenkins with AdministratorAccess role (lab account) | setup time | Least-privilege role + permission boundary, private Jenkins behind VPN/SSO |
