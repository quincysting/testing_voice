output "cluster_endpoint" {
  value = aws_rds_cluster.lab.endpoint
}

output "reader_endpoint" {
  value = aws_rds_cluster.lab.reader_endpoint
}

output "database_name" {
  value = var.database_name
}

output "master_username" {
  value = var.master_username
}

output "password_secret_arn" {
  value = aws_secretsmanager_secret.db_password.arn
}
