variable "region" {
  type    = string
  default = "us-east-1"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "cluster_version" {
  description = "Must be in EKS STANDARD support (extended support costs 6x). Check: aws eks describe-cluster-versions"
  type        = string
  default     = "1.33"
}

variable "node_capacity" {
  description = "SPOT (cheap) or ON_DEMAND (fallback)"
  type        = string
  default     = "SPOT"
}

variable "node_desired" {
  type    = number
  default = 2
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "key_name" {
  type    = string
  default = "shopnow-key"
}

variable "admin_principal_arns" {
  description = "IAM user/role ARNs of team members who need kubectl access"
  type        = list(string)
  default     = []
}

locals {
  name = "shopnow-${var.env}"
}
