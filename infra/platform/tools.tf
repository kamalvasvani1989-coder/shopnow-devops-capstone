# Small EC2 configured by Ansible (Sprint 3): Docker, kubectl, AWS CLI, node_exporter
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_security_group" "tools" {
  name        = "${local.name}-tools"
  description = "Tools EC2"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH from Jenkins over peering only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }
  ingress {
    description     = "node_exporter from EKS nodes/pods (Prometheus)"
    from_port       = 9100
    to_port         = 9100
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "tools" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = module.vpc.public_subnets[0]
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.tools.id]

  metadata_options { http_tokens = "required" }
  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
  }
  tags = { Name = "${local.name}-tools", Role = "tools" }
}
