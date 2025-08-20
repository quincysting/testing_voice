variable "app_name" {
  description = "Name of the application"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
  default     = "vpc-0d1467ee215ff5c37"
}

variable "ecs_cluster" {}
variable "kamailio_ec2_capacity_provider_name" {}
variable "voicemail_ec2_capacity_provider_name" {}
variable "imap_ec2_capacity_provider_name" {}
variable "environment" {
  description = "Environment for the application (e.g., lab, prod)"
  type        = string
}

variable "sbc_fs_subnets" {
  description = "List of subnet IDs for the Kamailio/SBC service"
  type        = list(string)
  #default     = ["subnet-06e973afc15d07937", "subnet-0cb1299ddd156c5c8"]
}

variable "repository_url" {
  description = "ECR repository URL for Kamailio container images"
  type        = string
  default     = "961341535886.dkr.ecr.ap-southeast-2.amazonaws.com/test/kamailio"
}

variable "image_tag" {
  description = "The tag of the Docker image to deploy"
  type        = string
  default     = "test"
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

variable "use_existing_cluster" {
  description = "Whether to use an existing ECS cluster instead of creating a new one"
  type        = bool
  default     = true
}

variable "existing_cluster_id" {
  description = "ID of an existing ECS cluster to use (when use_existing_cluster is true)"
  type        = string
  default     = ""
}

variable "alb_subnets" {
  description = "A list of subnets to associate with the Application Load Balancer. Should be public subnets."
  type        = list(string)
  default     = ["subnet-08e812930ead6e00d", "subnet-08af6b4eb1741cdcc"]
}

variable "kamailio_container_port" {
  description = "Port the kamailio container exposes and the NLB listens on."
  type        = number
  default     = 5060
}

variable "kamailio_server_desired_count" {
  description = "Desired number of imap-server tasks running."
  type        = number
  default     = 1
}

variable "s3_access_policy_arn" {
  description = "The ARN of the IAM policy that grants S3 access to the ECS tasks."
  type        = string
  default     = null # Or make it non-nullable if it's always required
}
