# Variables for optus-modules root configuration
# Note: config_prefix is defined in shared-config.tf

# Application names for different modules
# variable "app_name_admin_dashboard" {
#   description = "Name of the admin dashboard application"
#   type        = string
#   default     = "admin-dashboard-${local.env}" # "admin-dashboard-lab"
# }

# variable "app_name_imap" {
#   description = "Name of the IMAP application"
#   type        = string
#   #default     = "imap-${local.env}" # "imap-lab"
# }

# variable "app_name_freeswitch" {
#   description = "Name of the Freeswitch application"
#   type        = string
#   #default     = "freeswitch-${local.env}" #"freeswitch-lab"
# }

# variable "app_name_voicemail" {
#   description = "Name of the Voicemail application"
#   type        = string
#   #default     = "mozart-vmail-${local.env}" #"mozart-vmail-lab"
# }

# variable "app_name_sbc" {
#   description = "Name of the Kamailio application"
#   type        = string
#   #default     = "kamailio-sbc-${local.env}" #"kamailio-sbc-lab"
# }

# variable "app_name_worker" {
#   description = "Name of the Mozart worker application"
#   type        = string
#   default     = "mozart-worker-lab"
# }

# variable "app_name_smpp" {
#   description = "Name of the SMPP application"
#   type        = string
#   default     = "smpp-lab"
# }

# Network configuration
variable "alb_subnets" {
  description = "Subnets for Application Load Balancers"
  type        = list(string)
  default     = ["subnet-08e812930ead6e00d", "subnet-08af6b4eb1741cdcc"] # public subnets
}

# # Freeswitch specific variables
# variable "voicemail_ec2_capacity_provider_name" {
#   description = "Name of the EC2 capacity provider for voicemail/freeswitch"
#   type        = string
#   #default     = "voicemail-lab-ec2-capacity-provider"
# }

# variable "imap_ec2_capacity_provider_name" {
#   #default = "imap-lab-1-ec2-capacity-provider"
# }

# variable "kamailio_ec2_capacity_provider_name" {
#   description = "Name of the EC2 capacity provider for Kamailio"
#   type        = string
#   #default     = "kamailio-lab-ec2-capacity-provider"
# }

variable "voicemail_admin_dashboard_subnets" {
  description = "List of subnet IDs for the Voicemail service"
  type        = list(string)
  default     = ["subnet-02e98f9571d3c80bb", "subnet-0f3c678eeda1eccf6"] # Norwood Lab
}

variable "imap_subnets" {
  default = ["subnet-094b540ceb242d3e3", "subnet-0fc9c67feb60f11f9"] # Norwood Lab
}

variable "sbc_fs_subnets" {
  description = "List of subnet IDs for the Kamailio/SBC service"
  type        = list(string)
  default     = ["subnet-0364ace290f0abd0e", "subnet-0fe64a9dad23fc411"]
}

variable "worker_subnets" {
  description = "List of subnets for the service"
  type        = list(string)
  default     = ["subnet-031d0e1b69a135a2f", "subnet-01f371b1ca6c2b5b9"]

}

variable "lb_subnet1" {
  description = "Subnet for the load balancer"
  type        = string
  default     = "subnet-08e812930ead6e00d"
}

variable "lb_subnet2" {
  description = "Subnet for the load balancer"
  type        = string
  default     = "subnet-08af6b4eb1741cdcc"
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

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = ""
}

# variable "capacity_provider_smpp" {
#   description = "Name of the capacity provider to use for SMPP"
#   type        = string
#   default     = "imap-lab-1-ec2-capacity-provider"
# }