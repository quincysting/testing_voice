# output "smpp_ec2_capacity_provider_name" {
#   description = "Name of the EC2 capacity provider"
#   value       = aws_ecs_capacity_provider.ec2.name
# }

# Secrets are now managed externally and passed as variables
# output "secrets" {
#   value = var.secrets
# }

output "smpp_alb_dns_name" {
  description = "DNS name of the SMPP Application Load Balancer"
  value       = aws_lb.smpp_nlb.dns_name
}