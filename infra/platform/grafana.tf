# Lets Grafana (service account kps-grafana) read the AWS/Billing EstimatedCharges metric via EKS Pod Identity
resource "aws_iam_role" "grafana" {
  name = "${local.name}-grafana"
  assume_role_policy = jsonencode({ Version = "2012-10-17", Statement = [{
    Effect    = "Allow",
    Principal = { Service = "pods.eks.amazonaws.com" },
    Action    = ["sts:AssumeRole", "sts:TagSession"]
  }] })
}

resource "aws_iam_role_policy_attachment" "grafana" {
  role       = aws_iam_role.grafana.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}

resource "aws_eks_pod_identity_association" "grafana" {
  cluster_name    = module.eks.cluster_name
  namespace       = "monitoring"
  service_account = "kps-grafana"
  role_arn        = aws_iam_role.grafana.arn
}
