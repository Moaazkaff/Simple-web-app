output "ec2-public-ip" {
  description = "EC2 Public IP"
  value       = aws_instance.jenkins_ec2.public_ip
}