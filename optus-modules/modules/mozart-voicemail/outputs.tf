output "voicemail_ec2_capacity_provider_name" {
  description = "Name of the EC2 capacity provider"
  value       = aws_ecs_capacity_provider.ec2.name
}

output "mozart_voicemail_alb_name" {
  description = "Name of the Application Load Balancer for Mozart Voicemail"
  value       = aws_lb.voicemail.dns_name
}