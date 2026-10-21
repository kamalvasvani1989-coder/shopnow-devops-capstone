terraform {
  required_version = ">= 1.10"
  required_providers {
    aws  = { source = "hashicorp/aws", version = "~> 5.95" }
    http = { source = "hashicorp/http", version = "~> 3.4" }
  }
  # Replace <ACCOUNT_ID> with your 12-digit AWS account ID (same bucket as created in Step 0.2)
  backend "s3" {
    bucket       = "shopnow-tfstate-<ACCOUNT_ID>"
    key          = "bootstrap/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.region
  default_tags { tags = { Project = "shopnow", ManagedBy = "terraform", Layer = "persistent" } }
}
