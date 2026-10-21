module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.21"

  name                    = local.name
  cidr                    = var.vpc_cidr
  azs                     = var.azs
  public_subnets          = [cidrsubnet(var.vpc_cidr, 8, 1), cidrsubnet(var.vpc_cidr, 8, 2)]
  enable_nat_gateway      = false # biggest single saving (~$1.08/day)
  map_public_ip_on_launch = true

  public_subnet_tags = {
    "kubernetes.io/role/elb"              = 1 # lets Kubernetes place the load balancer
    "kubernetes.io/cluster/${local.name}" = "shared"
  }
}

# ---------- VPC peering: Jenkins (default VPC) <-> project VPC
data "aws_vpc" "default" { default = true }
data "aws_route_tables" "default" { vpc_id = data.aws_vpc.default.id }

resource "aws_vpc_peering_connection" "jenkins" {
  vpc_id      = module.vpc.vpc_id
  peer_vpc_id = data.aws_vpc.default.id
  auto_accept = true
  tags        = { Name = "${local.name}-to-default" }
}

resource "aws_route" "project_to_default" {
  route_table_id            = module.vpc.public_route_table_ids[0]
  destination_cidr_block    = data.aws_vpc.default.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.jenkins.id
}

resource "aws_route" "default_to_project" {
  for_each                  = toset(data.aws_route_tables.default.ids)
  route_table_id            = each.value
  destination_cidr_block    = var.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.jenkins.id
}
