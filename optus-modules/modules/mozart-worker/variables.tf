variable "ecs_cluster" {}
variable "vpc_id" {}
variable "kamailio_ec2_capacity_provider_name" {}
variable "voicemail_ec2_capacity_provider_name" {}
variable "imap_ec2_capacity_provider_name" {}
variable "app_name" {
  description = "Name of the application"
  type        = string
}

variable "desired_count" {
  description = "Desired number of tasks in the service"
  type        = number
  default     = 1

}

variable "worker_subnets" {
  description = "List of subnets for the service"
  type        = list(string)
  #default     = ["subnet-0f3312b3c67f5540c", "subnet-0fd7ee0ab0d8798ea"]
}

variable "repository_url" {
  description = "ECR repository URL for Mozart Worker container images"
  type        = string
  default     = "607570804706.dkr.ecr.ap-southeast-2.amazonaws.com/mozart:voicemail-worker-0.9.6.2" #"961341535886.dkr.ecr.ap-southeast-2.amazonaws.com/mozart"

}

variable "image_tag" {
  description = "Container image tag to deploy"
  type        = string
  default     = "voicemail-worker-0.9.6.2"
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

variable "config_prefix" {
  description = "Prefix for SSM parameters and secrets"
  type        = string
  default     = "/mozart-tactical-lab"
}

variable "voicemail_container_port" {
  description = "Port the voicemail server container exposes."
  type        = number
  default     = 8080
}

variable "container_port" {
  description = "Port the container exposes"
  type        = number
  default     = 8080
}

variable "imap_server_container_port" {
  description = "Port the imap-server container exposes and the NLB listens on."
  type        = number
  default     = 8080
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = ""
}