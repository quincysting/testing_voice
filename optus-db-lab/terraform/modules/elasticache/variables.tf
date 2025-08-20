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
  description = "List of subnet IDs for the ElastiCache cluster"
  type        = list(string)
  default     = ["subnet-031d0e1b69a135a2f", "subnet-01f371b1ca6c2b5b9"]
}

variable "node_type" {
  description = "The instance class to be used"
  type        = string
  default     = "cache.t3.micro"
}

variable "engine_version" {
  description = "Version number of the Redis engine"
  type        = string
  default     = "6.x"
}

variable "parameter_group_name" {
  description = "The name of the parameter group to associate with this cache cluster"
  type        = string
  default     = "default.redis6.x"
}
