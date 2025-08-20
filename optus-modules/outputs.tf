output "voicemail_alb_dns_name" {
  description = "Name of the Mozart Voicemail Application Load Balancer"
  value       = module.mozart-voicemail.mozart_voicemail_alb_name
}

output "admin_dashboard_alb_dns_name" {
  value = module.admin-dashboard.admin_dashboard_alb_dns_name
  description = "DNS name of the Admin Dashboard ALB"
}

output "freeswitch_nlb_dns_name" {
  description = "DNS name of the Network Load Balancer"
  value       = module.freeswitch.freeswitch_nlb_dns_name
}

output "imap_alb_dns_name" {
  description = "DNS name of the IMAP Application Load Balancer"
  value       = module.imap.imap_alb_dns_name
}

output "kamailio_nlb_dns_name" {
  description = "DNS name of the Kamailio Network Load Balancer"
  value       = module.sbc-kamailio.kamailio_nlb_dns_name
}

output "smpp_alb_dns_name" {
  description = "DNS name of the SMPP Application Load Balancer"
  value       = module.smpp.smpp_alb_dns_name
}

#####################################################
# output "worker_alb_dns_name" {
#   description = "DNS name of the Worker Application Load Balancer"
#   value       = module.worker.worker_alb_dns_name
# }

# output "public_subnet_ids" {
#   value = local.public_subnets
# }

# output "private_subnet_ids" {
#   value = local.private_subnets
# }

# output "database_subnet_ids" {
#   value = local.database_subnets
# }

# output "secret" {
#   value = module.imap.secrets
# }

# output "mozart_vmail_alb" {
#   description = "Name of the Mozart Voicemail Application Load Balancer"
#   value       = module.mozart-voicemail.mozart_voicemail_alb_name

# }

# output "sbc_cp" {
#   value = local.kamailio_ec2_capacity_provider_name
# }

# output "voicemail_cp" {
#   value = local.voicemail_ec2_capacity_provider_name
# }

# output "imap_cp" {
#   value = local.imap_ec2_capacity_provider_name

# }
