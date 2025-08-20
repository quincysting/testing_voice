# Legacy configuration management code - REPLACED
# 
# All SSM parameters and secrets management has been moved to:
# - shared-config.tf for centralized configuration
# - optus-scripts/ for external parameter/secret creation
# 
# This approach provides better separation of concerns and follows
# modern Terraform best practices.

locals {
  #env = "lab"
  env                                  = "tactical-lab"
  app_name_admin_dashboard             = "admin-dashboard-${local.env}"
  app_name_imap                        = "imap-${local.env}"
  app_name_freeswitch                  = "freeswitch-${local.env}"
  app_name_voicemail                   = "voicemail-${local.env}"
  app_name_sbc                         = "kamailio-sbc-${local.env}"
  app_name_worker                      = "mozart-worker-${local.env}"
  app_name_smpp                        = "smpp-${local.env}"
  voicemail_ec2_capacity_provider_name = "voicemail-${local.env}-ec2-capacity-provider"
  imap_ec2_capacity_provider_name      = "imap-${local.env}-ec2-capacity-provider"
  kamailio_ec2_capacity_provider_name  = "kamailio-sbc-${local.env}-ec2-capacity-provider"
  capacity_provider_smpp               = "imap-${local.env}-ec2-capacity-provider"
}

