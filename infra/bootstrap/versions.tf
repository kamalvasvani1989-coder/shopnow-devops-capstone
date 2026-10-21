terraform {
  required_version = ">= 1.10"
  required_providers {
    aws  = { source = "hashicorp/aws", version = "~> 5.95" }
    http = { source = "hashicorp/http", version = "~> 3.4" }
  }
  # Replace 926375049914 with your 12-digit AWS account ID (same bucket as created in Step 0.2)
  backend "s3" {
    bucket       = "shopnow-tfstate-926375049914"
    key          = "bootstrap/terraform.tfstate"
    region       = "ap-southeast-2"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.region
  default_tags { tags = { Project = "shopnow", ManagedBy = "terraform", Layer = "persistent" } }
}
