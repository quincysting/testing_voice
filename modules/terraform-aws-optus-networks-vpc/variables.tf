# VPC Flow Log Variables
variable "enable_flow_log" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = false
}

variable "flow_log_destination_type" {
  description = "The type of destination for VPC Flow Logs. Valid values: cloud-watch-logs, s3"
  type        = string
  default     = "cloud-watch-logs"
  validation {
    condition     = contains(["cloud-watch-logs", "s3"], var.flow_log_destination_type)
    error_message = "flow_log_destination_type must be either 'cloud-watch-logs' or 's3'."
  }
}

variable "flow_log_s3_arn" {
  description = "S3 bucket ARN for VPC Flow Logs (required when destination_type is s3)"
  type        = string
  default     = null
}

variable "flow_log_traffic_type" {
  description = "The type of traffic to capture. Valid values: ACCEPT, REJECT, ALL"
  type        = string
  default     = "ALL"
  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.flow_log_traffic_type)
    error_message = "flow_log_traffic_type must be one of: ACCEPT, REJECT, ALL."
  }
}

variable "flow_log_retention_days" {
  description = "CloudWatch log group retention in days"
  type        = number
  default     = 14
}

variable "flow_log_format" {
  description = "The format for the flow log. Default format captures essential fields."
  type        = string
  default     = "$${version} $${account-id} $${interface-id} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${protocol} $${packets} $${bytes} $${windowstart} $${windowend} $${action} $${flowlogstatus}"
}

# Existing variables (add these if not already present)
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_secondary_cidrs" {
  description = "List of secondary CIDR blocks for the VPC"
  type        = list(string)
  default     = []
}

variable "subnets" {
  description = "Map of subnets to create"
  type = map(object({
    cidr              = string
    availability_zone = string
    route_table       = string
  }))
}

variable "route_tables" {
  description = "Map of route tables to create"
  type = map(object({
    routes = list(object({
      destination         = string
      transit_gateway_id = optional(string)
    }))
  }))
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}