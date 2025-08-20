# variable "app_name" {
#   default = "lab-"
# }

variable "app_name" {}
variable "vpc_id" {}
variable "ecs_cluster" {}
variable "kamailio_ec2_capacity_provider_name" {}
variable "voicemail_ec2_capacity_provider_name" {}
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-2"
}
variable "config_prefix" {
  description = "Prefix for SSM parameters and secrets"
  type        = string
  default     = "/mozart-tactical-lab"
}
variable "ecs_ami_id" {
  default = "ami-083d56d17cad6cf58"
}
variable "instance_type" {
  default = "t3.medium"
}
variable "imap_server_container_port" {
  description = "Port the imap-server container exposes and the NLB listens on."
  type        = number
  default     = 8080
}

variable "imap_server_desired_count" {
  description = "Desired number of imap-server tasks running."
  type        = number
  default     = 1
}

variable "alb_subnets" {
  #default = ["subnet-06e7470e43d97cbc0", "subnet-04c53e37b36d59ed6"]
  #default = ["subnet-0e42ed580f3069fae", "subnet-0f26eace80a2d48df"] #public subnets
}

variable "imap_subnets" {
  #default = ["subnet-0dd3ae5e66ab68ad6", "subnet-04cae304eef694a1c"]
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
  description = "ECR repository URL for IMAP server container images"
  type        = string
  default     = "607570804706.dkr.ecr.ap-southeast-2.amazonaws.com/imap-server"
}

variable "image_tag" {
  description = "Container image tag to deploy"
  type        = string
  default     = "0.9.6.2"
}

variable "container_port" {
  description = "Port the container exposes"
  type        = number
  default     = 8080
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

variable "lb_subnet1_cidr_block" {
  description = "Subnet for the load balancer"
  type        = string

}

variable "lb_subnet2_cidr_block" {
  description = "Subnet for the load balancer"
  type        = string
}
