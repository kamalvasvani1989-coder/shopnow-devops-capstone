output "cluster_name" { value = module.eks.cluster_name }
output "region" { value = var.region }
output "tools_private_ip" { value = aws_instance.tools.private_ip }
output "vpc_id" { value = module.vpc.vpc_id }
