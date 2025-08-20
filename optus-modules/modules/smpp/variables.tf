# variable "app_name" {
#   default = "lab-"
# }

variable "app_name" {}
variable "vpc_id" {}
variable "ecs_cluster" {}
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
variable "smpp_server_container_port" {
  description = "Port the smpp-server container exposes and the NLB listens on."
  type        = number
  default     = 8144 #1775
}

variable "smpp_server_desired_count" {
  description = "Desired number of smpp-server tasks running."
  type        = number
  default     = 1
}

variable "alb_subnets" {
  default = ["subnet-08e812930ead6e00d", "subnet-08af6b4eb1741cdcc"] #public subnets
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
  description = "ECR repository URL for SMPP server container images"
  type        = string
  default     = "607570804706.dkr.ecr.ap-southeast-2.amazonaws.com/smpp-service"
}

variable "image_tag" {
  description = "Container image tag to deploy"
  type        = string
  default     = "0.9.1.2" #"0.9.0.0"
}

variable "container_port" {
  description = "Port the container exposes"
  type        = number
  default     = 1775
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

variable "capacity_provider_for_smpp" {
  description = "Name of the capacity provider to use"
  type        = string
}