module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.37"

  cluster_name                             = local.name
  cluster_version                          = var.cluster_version
  vpc_id                                   = module.vpc.vpc_id
  subnet_ids                               = module.vpc.public_subnets
  cluster_endpoint_public_access           = true
  authentication_mode                      = "API"
  enable_cluster_creator_admin_permissions = true  # the Jenkins role becomes cluster admin
  enable_irsa                              = false # free-plan SCP denies iam:CreateOpenIDConnectProvider; pods use EKS Pod Identity instead

  # ---- cost switches
  create_kms_key              = false
  cluster_encryption_config   = {}
  cluster_enabled_log_types   = []
  create_cloudwatch_log_group = false

  cluster_addons = {
    vpc-cni                = { before_compute = true }
    coredns                = {}
    kube-proxy             = {}
    eks-pod-identity-agent = {}
  }

  eks_managed_node_groups = {
    workers = {
      capacity_type              = var.node_capacity
      instance_types             = var.node_instance_types
      min_size                   = 1
      max_size                   = 2
      desired_size               = var.node_desired
      use_custom_launch_template = false
      disk_size                  = 20
    }
  }

  access_entries = { for i, arn in var.admin_principal_arns : "member${i}" => {
    principal_arn = arn
    policy_associations = {
      admin = {
        policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
        access_scope = { type = "cluster" }
      }
    }
  } }
}
