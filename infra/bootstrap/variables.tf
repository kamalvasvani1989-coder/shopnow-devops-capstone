variable "region" {
  type    = string
  default = "ap-southeast-2"
}

variable "team_cidrs" {
  description = "Public IPs of team members as x.x.x.x/32 (Jenkins UI + SSH)"
  type        = list(string)
}

variable "key_name" {
  description = "EC2 key pair created manually in Step 0.1"
  type        = string
  default     = "shopnow-key"
}

variable "jenkins_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "project_vpc_cidr" {
  description = "CIDR of the disposable project VPC (allowed to scrape Jenkins over peering)"
  type        = string
  default     = "10.0.0.0/16"
}
