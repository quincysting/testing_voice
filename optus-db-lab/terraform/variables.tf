# Configuration prefix for SSM parameters and secrets
# This should match the prefix used in optus-modules and optus-scripts
variable "config_prefix" {
  description = "Prefix for SSM parameters and secrets (should match optus-modules)"
  type        = string
  default     = "/mozart-tactical-lab"
}