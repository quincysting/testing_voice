variable "route_tables" {
  description = "Map of route tables to create."
  type = map(object({
    routes = optional(list(object({
      destination        = string
      transit_gateway_id = optional(string, null)
    })), [])
  }))
  default = {}
}

variable "subnets" {
  description = "Map of subnets to create."
  type = map(object({
    availability_zone = string
    cidr              = string
    route_table       = optional(string, "default")
  }))
}

variable "tags" {
  description = "A map of tags to assign to assign to all resources."
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  description = "Primary CIDR block for the VPC."
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC."
  type        = string
}

variable "vpc_secondary_cidrs" {
  description = "List of secondary CIDR blocks to associate with the VPC."
  type        = list(string)
  default     = []
}
