variable "app_name" {
  description = "Name of the application"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "alb_subnets" {
  description = "List of subnet IDs for the load balancer"
  type        = list(string)
}

variable "ecs_cluster" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "subnets" {
  description = "List of subnet IDs for the ECS service (same as kamailio module)"
  type        = list(string)
  default     = ["subnet-0364ace290f0abd0e", "subnet-0fe64a9dad23fc411"] # Same as kamailio module
}

variable "capacity_provider_name" {
  description = "Name of the capacity provider to use"
  type        = string
}

# Additional variables needed by freeswitch module
# variable "voicemail_ec2_capacity_provider_name" {
#   description = "Name of the EC2 capacity provider for voicemail/freeswitch"
#   type        = string
#   default     = "voicemail-lab-ec2-capacity-provider"
# }

variable "sbc_fs_subnets" {
  description = "List of subnet IDs for the Kamailio/SBC service"
  type        = list(string)
  #default     = ["subnet-06e973afc15d07937", "subnet-0cb1299ddd156c5c8"]
}

variable "ecs_ami_id" {
  description = "AMI ID for ECS instances"
  type        = string
  default     = "ami-083d56d17cad6cf58" # ECS optimized AMI for ap-southeast-2
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

# Shared configuration variables (optional for freeswitch)
variable "config_prefix" {
  description = "Prefix for SSM parameters and secrets"
  type        = string
  default     = "/mozart-tactical-lab"
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

variable "kamailio_nlb_security_group_id" {
  description = "Security group ID for Kamailio NLB (from SBC module)"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = ""
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for media uploads"
  type        = string
}

variable "mozart_server" {
  description = "Mozart server URL for media uploads"
  type        = string
}