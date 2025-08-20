# Admin dashboard module outputs
# All shared data sources (ECR, Redis, RDS) are now managed at the top level
# and accessible via data.aws_ecr_repository.admin_dashboard_ecr, etc.

output "admin_dashboard_alb_dns_name" {
  description = "DNS name of the Admin Dashboard ALB"
  value       = aws_lb.admin_dashboard.dns_name
}