terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.95" }
  }
  # Replace <ACCOUNT_ID>. Each Terraform workspace (dev/prod) gets its own state under env:/<workspace>/
  backend "s3" {
    bucket       = "shopnow-tfstate-<ACCOUNT_ID>"
    key          = "platform/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.region
  default_tags { tags = { Project = "shopnow", ManagedBy = "terraform", Layer = "disposable", Env = var.env } }
}
