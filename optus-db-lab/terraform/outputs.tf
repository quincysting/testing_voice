# Output database password secret ARNs for use in shared configuration
output "aurora_db_password_secret_arn" {
  description = "ARN of the Aurora RDS password secret for SUBSCRIBER_DB_PASSWORD"
  value       = module.aurora_rds.password_secret_arn
}

output "kamailio_db_password_secret_arn" {
  description = "ARN of the Kamailio RDS password secret for KAM_DB_PASSWORD"
  value       = module.kamailio_rds.password_secret_arn
}

# Output database connection details for dynamic connection string construction
output "aurora_cluster_endpoint" {
  description = "Aurora RDS cluster endpoint"
  value       = module.aurora_rds.cluster_endpoint
}

output "aurora_database_name" {
  description = "Aurora RDS database name"
  value       = module.aurora_rds.database_name
}

output "aurora_master_username" {
  description = "Aurora RDS master username"
  value       = module.aurora_rds.master_username
}

output "kamailio_cluster_endpoint" {
  description = "Kamailio RDS cluster endpoint"
  value       = module.kamailio_rds.cluster_endpoint
}

output "kamailio_database_name" {
  description = "Kamailio RDS database name"
  value       = module.kamailio_rds.database_name
}

output "kamailio_master_username" {
  description = "Kamailio RDS master username"
  value       = module.kamailio_rds.master_username
}