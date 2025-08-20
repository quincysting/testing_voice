# VPC Flow Log Outputs
output "flow_log_id" {
  description = "The Flow Log ID"
  value       = var.enable_flow_log ? aws_flow_log.vpc_flow_log[0].id : null
}

output "flow_log_cloudwatch_log_group_name" {
  description = "The name of the CloudWatch Log Group for VPC Flow Logs"
  value       = var.enable_flow_log && var.flow_log_destination_type == "cloud-watch-logs" ? aws_cloudwatch_log_group.vpc_flow_log[0].name : null
}

output "flow_log_cloudwatch_log_group_arn" {
  description = "The ARN of the CloudWatch Log Group for VPC Flow Logs"
  value       = var.enable_flow_log && var.flow_log_destination_type == "cloud-watch-logs" ? aws_cloudwatch_log_group.vpc_flow_log[0].arn : null
}

output "flow_log_iam_role_arn" {
  description = "The ARN of the IAM Role for VPC Flow Logs"
  value       = var.enable_flow_log && var.flow_log_destination_type == "cloud-watch-logs" ? aws_iam_role.flow_log[0].arn : null
}

# Existing VPC outputs (add these if not already present)
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = aws_vpc.this.arn
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "subnet_ids" {
  description = "Map of subnet names to IDs"
  value       = { for k, v in aws_subnet.this : k => v.id }
}

output "route_table_ids" {
  description = "Map of route table names to IDs"
  value       = { for k, v in aws_route_table.this : k => v.id }
}