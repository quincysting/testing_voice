variable "environment" {
  default = "lab"
}

variable "app_name" {
  description = "Name of the application"
  type        = string
  default     = "admin-dashboard-lab"
}

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "ecs_cluster" {
  description = "ECS cluster name"
  type        = string
}

variable "config_prefix" {
  description = "Prefix for SSM parameters and secrets"
  type        = string
  default     = "/mozart-tactical-lab"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-2"
}

# Removed old secret-ssm variable - now using config_prefix

variable "elasticache-primary_endpoint" {
  default = "test"
}

variable "elasticache-port" {
  default = "25"
}

variable "rds-master_username" {
  default = "test"
}

variable "capacity_provider" {
  # default = "mozart-vmail-lab-ec2-capacity-provider" #"voicemail-lab-ec2-capacity-provider"
}


variable "admin_dashboard_image_tag" {
  description = "Admin dashboard container image tag to deploy"
  type        = string
  default     = "latest"
}

variable "cpu" {
  description = "CPU units for the task"
  type        = number
  default     = 2048
}

variable "memory" {
  description = "Memory for the task in MiB"
  type        = number
  default     = 2048
}

variable "repository_url" {
  description = "ECR repository URL for Admin Dashboard container images"
  type        = string
  default     = "607570804706.dkr.ecr.ap-southeast-2.amazonaws.com/admin-dashboard"
}

variable "image_tag" {
  description = "Container image tag to deploy"
  type        = string
  default     = "0.9.6.2"
}

variable "admin-dashboard_container_port" {
  description = "Port the admin dashboard container exposes and the NLB listens on."
  type        = number
  default     = 80
}

variable "environment_variables" {
  description = "Environment variables for the container (non-sensitive)"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "secrets" {
  description = "Secrets to pass to the container (from Secrets Manager or SSM Parameter Store)"
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

variable "alb_subnets" {
  #default = ["subnet-06e7470e43d97cbc0", "subnet-04c53e37b36d59ed6"]
  #default = ["subnet-0e42ed580f3069fae", "subnet-0f26eace80a2d48df"] #public subnets
}

variable "voicemail_admin_dashboard_subnets" {
  #default = ["subnet-0720ec03ad90416c3", "subnet-0884a63641d24170f"]
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = ""
}