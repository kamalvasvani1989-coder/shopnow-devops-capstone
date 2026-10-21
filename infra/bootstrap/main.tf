data "aws_vpc" "default" { default = true }

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

# GitHub webhook source ranges (IPv4 only)
data "http" "github_meta" { url = "https://api.github.com/meta" }
locals {
  github_hooks = [for c in jsondecode(data.http.github_meta.response_body).hooks : c if !strcontains(c, ":")]
}

# ---------------- ECR (persists across cluster teardowns)
resource "aws_ecr_repository" "app" {
  for_each     = toset(["shopnow-frontend", "shopnow-admin", "shopnow-backend"])
  name         = each.key
  force_delete = true
  image_scanning_configuration { scan_on_push = true }
}

resource "aws_ecr_lifecycle_policy" "keep5" {
  for_each   = aws_ecr_repository.app
  repository = each.value.name
  policy = jsonencode({ rules = [{
    rulePriority = 1, description = "keep last 5 images",
    selection    = { tagStatus = "any", countType = "imageCountMoreThan", countNumber = 5 },
    action       = { type = "expire" }
  }] })
}

# ---------------- Jenkins IAM role (no access keys in Jenkins)
resource "aws_iam_role" "jenkins" {
  name = "shopnow-jenkins-role"
  assume_role_policy = jsonencode({ Version = "2012-10-17", Statement = [{
    Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" }, Action = "sts:AssumeRole"
  }] })
}

# Accepted risk (lab account only): Terraform must create IAM roles for EKS.
# Compensating controls: SG restricted to team IPs + GitHub, Jenkins auth, IMDSv2.
resource "aws_iam_role_policy_attachment" "jenkins_admin" {
  role       = aws_iam_role.jenkins.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "jenkins" {
  name = "shopnow-jenkins-profile"
  role = aws_iam_role.jenkins.name
}

# ---------------- Jenkins security group
resource "aws_security_group" "jenkins" {
  name        = "shopnow-jenkins-sg"
  description = "Jenkins server"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH from team"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.team_cidrs
  }
  ingress {
    description = "Jenkins UI from team + GitHub webhooks"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = concat(var.team_cidrs, local.github_hooks)
  }
  ingress {
    description = "Prometheus scrape of Jenkins over VPC peering"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.project_vpc_cidr]
  }
  ingress {
    description = "Prometheus scrape of node_exporter over VPC peering"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = [var.project_vpc_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------- Jenkins EC2 (stop it when idle)
resource "aws_instance" "jenkins" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.jenkins_instance_type
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.jenkins.name
  vpc_security_group_ids = [aws_security_group.jenkins.id]
  user_data              = file("${path.module}/jenkins-userdata.sh")

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }
  metadata_options {
    http_tokens                 = "required" # IMDSv2 only
    http_put_response_hop_limit = 2          # lets Docker builds reach the instance role
  }
  tags = { Name = "shopnow-jenkins", Role = "jenkins" }

  lifecycle { ignore_changes = [ami, user_data] }
}
