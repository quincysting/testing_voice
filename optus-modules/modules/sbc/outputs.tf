output "kamailio_ec2_capacity_provider_name" {
  description = "Name of the EC2 capacity provider"
  value       = aws_ecs_capacity_provider.ec2.name
}

output "kamailio_nlb_security_group_id" {
  description = "Security group ID for Kamailio NLB"
  value       = aws_security_group.kamailio_nlb.id
}

output "kamailio_nlb_dns_name" {
  description = "DNS name of the Kamailio Network Load Balancer"
  value       = aws_lb.kamailio.dns_name
  
}