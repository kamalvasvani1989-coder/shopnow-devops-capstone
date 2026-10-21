output "jenkins_url" { value = "http://${aws_instance.jenkins.public_ip}:8080" }
output "jenkins_instance_id" { value = aws_instance.jenkins.id }
output "jenkins_private_ip" { value = aws_instance.jenkins.private_ip }
output "ecr_repos" { value = { for k, r in aws_ecr_repository.app : k => r.repository_url } }
