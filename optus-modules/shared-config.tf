# Shared configuration for all modules
# This defines the standard SSM parameter names that should exist
# Parameters are created externally using optus-scripts/create-ssm-parameters.sh

# Configurable prefix to match the scripts in optus-scripts/
variable "config_prefix" {
  description = "Prefix for SSM parameters and secrets (should match scripts)"
  type        = string
  default     = ""
}

locals {
  config_prefix = var.config_prefix != "" ? var.config_prefix : "/tactical-lab"
  
  # Centralized SSM parameter names - these should exist before deploying modules
  shared_ssm_parameters = {
    "AWS_REGION"          = "${local.config_prefix}/AWS_REGION"
    "APNS_ENVIRONMENT"    = "${local.config_prefix}/APNS_ENVIRONMENT"
    "SMS_PROVIDER"        = "${local.config_prefix}/SMS_PROVIDER"
    "EMAIL_PROVIDER"      = "${local.config_prefix}/EMAIL_PROVIDER"
    "AWS_S3_BUCKET_NAME"  = "${local.config_prefix}/AWS_S3_BUCKET_NAME"
    "TWILIO_ACCOUNT_SID"  = "${local.config_prefix}/TWILIO_ACCOUNT_SID"
    "SMS_FROM_NUMBER"     = "${local.config_prefix}/SMS_FROM_NUMBER"
    "AWS_FROM_EMAIL"      = "${local.config_prefix}/AWS_FROM_EMAIL"
    "SMPP_SYSTEM_ID"      = "${local.config_prefix}/SMPP_SYSTEM_ID"
    "RUN_REAL_SMS_TESTS"  = "${local.config_prefix}/RUN_REAL_SMS_TESTS"
    "SMPP_SERVER_HOST"    = "${local.config_prefix}/SMPP_SERVER_HOST"
    "SMPP_SOURCE_ADDRESS" = "${local.config_prefix}/SMPP_SOURCE_ADDRESS"
    "TEST_SMS_RECIPIENT"  = "${local.config_prefix}/TEST_SMS_RECIPIENT"
    "SMSGLOBAL_USERNAME"  = "${local.config_prefix}/SMSGLOBAL_USERNAME"
  }

  # Kamailio-specific configuration parameters
  kamailio_config = {
    "PATH" = "/usr/sbin/kamailio:/usr/sbin/:/usr/bin:/usr/local:/usr/local/sbin/"
  }

  # Centralized secret names - these should exist before deploying modules
  shared_secret_names = [
    "JWT_SECRET",
    "AUTH_PASSWORD",
    "TWILIO_AUTH_TOKEN",
    "SMPP_PASSWORD",
    "SMSGLOBAL_PASSWORD"
  ]

  # Database-specific secret names with their actual secret names in AWS
  database_secret_names = {
    "SUBSCRIBER_DB_PASSWORD" = "mozart-db-${local.env}-db-password-lab"
    "KAM_DB_PASSWORD"        = "kamailio-db-${local.env}-db-password-lab"
  }

  # Dynamic connection strings constructed from infrastructure data sources
  # This follows best practice by using actual infrastructure endpoints and secrets
  dynamic_connections = {
    "DB_CONNECTION"    = "postgres://${data.aws_rds_cluster.rds.master_username}:${data.aws_secretsmanager_secret_version.subscriber_db_password.secret_string}@${data.aws_rds_cluster.rds.endpoint}/${data.aws_rds_cluster.rds.database_name}?sslmode=disable"
    "REDIS_CONNECTION" = "redis://${data.aws_elasticache_replication_group.redis-endpoint.primary_endpoint_address}:${data.aws_elasticache_replication_group.redis-endpoint.port}"
    "DBURL"            = "postgres://${data.aws_rds_cluster.kamailio_rds.master_username}:${data.aws_secretsmanager_secret_version.kamailio_db_password.secret_string}@${data.aws_rds_cluster.kamailio_rds.endpoint}/${data.aws_rds_cluster.kamailio_rds.database_name}"
  }

  # Kamailio-specific database connection
  kamailio_db_connection = {
    "KAMAILIO_DBURL" = "postgres://${data.aws_rds_cluster.kamailio_rds.master_username}:${data.aws_secretsmanager_secret_version.kamailio_db_password.secret_string}@${data.aws_rds_cluster.kamailio_rds.endpoint}/${data.aws_rds_cluster.kamailio_rds.database_name}"
  }
}

# Data sources for shared SSM parameters
data "aws_ssm_parameter" "shared_config" {
  for_each = local.shared_ssm_parameters
  name     = each.value
}

# Data sources for shared secrets
data "aws_secretsmanager_secret" "shared_secrets" {
  for_each = toset(local.shared_secret_names)
  name     = "${local.config_prefix}/${each.key}"
}

# Data sources for dynamic connection construction
data "aws_rds_cluster" "rds" {
  cluster_identifier = "mozart-db-${local.env}-cluster"
}

data "aws_rds_cluster" "kamailio_rds" {
  cluster_identifier = "kamailio-db-${local.env}-cluster"
}

data "aws_elasticache_replication_group" "redis-endpoint" {
  replication_group_id = "mozart-redis-${local.env}"
}

# Get subscriber database password for dynamic connection construction
data "aws_secretsmanager_secret_version" "subscriber_db_password" {
  secret_id = data.aws_secretsmanager_secret.database_secrets["SUBSCRIBER_DB_PASSWORD"].id
}

# Get Kamailio database password for SBC module
data "aws_secretsmanager_secret_version" "kamailio_db_password" {
  secret_id = data.aws_secretsmanager_secret.database_secrets["KAM_DB_PASSWORD"].id
}

# Data sources for database-specific secrets (created by database modules)
data "aws_secretsmanager_secret" "database_secrets" {
  for_each = local.database_secret_names
  name     = each.value
}
