variable "app_name" {
  description = "Name of the application"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
  default     = "vpc-0d1467ee215ff5c37"
}

variable "subnets" {
  description = "List of subnet IDs for the RDS cluster"
  type        = list(string)
  default     = ["subnet-031d0e1b69a135a2f", "subnet-01f371b1ca6c2b5b9"]
}

variable "instance_class" {
  description = "Instance class for the RDS instances"
  type        = string
  default     = "db.t3.medium"
}

variable "database_name" {
  description = "Name of the database to create"
  type        = string
  default     = "kamailio"
}

variable "master_username" {
  description = "Master username for the database"
  type        = string
  default     = "norwood_dev"
}

variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 2
}

