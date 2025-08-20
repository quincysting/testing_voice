output "freeswitch_nlb_dns_name" {
  description = "DNS name of the Network Load Balancer"
  value       = aws_lb.freeswitch.dns_name
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.freeswitch.arn
}