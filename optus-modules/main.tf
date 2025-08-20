# module "ecs_cluster" {
#     source = "./modules/ecs-cluster"
#     name   = var.app_name
# }
#############################################################################

module "sbc-kamailio" {
  source                               = "./modules/sbc"
  app_name                             = local.app_name_sbc #var.app_name_sbc
  vpc_id                               = data.aws_vpc.optus-vpc.id
  alb_subnets                          = var.alb_subnets
  ecs_cluster                          = data.aws_ecs_cluster.existing.cluster_name
  voicemail_ec2_capacity_provider_name = local.voicemail_ec2_capacity_provider_name
  kamailio_ec2_capacity_provider_name  = local.kamailio_ec2_capacity_provider_name
  imap_ec2_capacity_provider_name      = local.imap_ec2_capacity_provider_name
  environment                          = local.env
  sbc_fs_subnets = var.sbc_fs_subnets

  # Pass shared configuration and secrets to the module
  secrets = concat(
    # Non-sensitive parameters from SSM Parameter Store
    [
      for key in keys(data.aws_ssm_parameter.shared_config) : {
        name      = key
        valueFrom = data.aws_ssm_parameter.shared_config[key].arn
      }
    ],
    # Sensitive values from Secrets Manager
    [
      for key in keys(data.aws_secretsmanager_secret.shared_secrets) : {
        name      = key
        valueFrom = data.aws_secretsmanager_secret.shared_secrets[key].arn
      }
    ],
    # Database passwords from database modules
    [
      for key in keys(data.aws_secretsmanager_secret.database_secrets) : {
        name      = key
        valueFrom = data.aws_secretsmanager_secret.database_secrets[key].arn
      }
    ],
    # Add DBPW for docker-entrypoint.sh
    [
      {
        name      = "DBPW"
        valueFrom = data.aws_secretsmanager_secret.database_secrets["KAM_DB_PASSWORD"].arn
      }
    ]
  )

  # Pass kamailio-specific configuration and dynamic connections as environment variables
  environment_variables = concat(
    # Include general dynamic connections (except DBURL which we'll override)
    [
      for key, value in local.dynamic_connections : {
        name  = key
        value = value
      } if key != "DBURL"
    ],
    # Add Kamailio-specific DBURL
    [
      {
        name  = "DBURL"
        value = local.kamailio_db_connection["KAMAILIO_DBURL"]
      }
    ],
    [
      for key, value in local.kamailio_config : {
        name  = key
        value = value
      }
    ],
    # Add individual database parameters for docker-entrypoint.sh
    # Using the dedicated Kamailio database
    [
      {
        name  = "DBHOST"
        value = data.aws_rds_cluster.kamailio_rds.endpoint
      },
      {
        name  = "DBPORT"
        value = "5432"
      },
      {
        name  = "DBNAME"
        value = data.aws_rds_cluster.kamailio_rds.database_name
      },
      {
        name  = "DBUSER"
        value = data.aws_rds_cluster.kamailio_rds.master_username
      },
      {
        name  = "ENABLE_TLS"
        value = "false"
      }
    ]
  )
}

#############################################################################
module "mozart-voicemail" {
  source      = "./modules/mozart-voicemail"
  app_name    = local.app_name_voicemail #var.app_name_voicemail
  vpc_id      = data.aws_vpc.optus-vpc.id
  alb_subnets = var.alb_subnets
  ecs_cluster = data.aws_ecs_cluster.existing.cluster_name
  #voicemail_ec2_capacity_provider_name = local.voicemail_ec2_capacity_provider_name
  kamailio_ec2_capacity_provider_name = local.kamailio_ec2_capacity_provider_name
  #imap_ec2_capacity_provider_name      = local.imap_ec2_capacity_provider_name
  vpc_cidr_block = data.aws_vpc.optus-vpc.cidr_block
  environment    = local.env
  voicemail_admin_dashboard_subnets = var.voicemail_admin_dashboard_subnets
  depends_on     = [module.sbc-kamailio]

  # Pass shared configuration and secrets to the module
  secrets = concat(
    # Non-sensitive parameters from SSM Parameter Store
    [
      for key in keys(data.aws_ssm_parameter.shared_config) : {
        name      = key
        valueFrom = data.aws_ssm_parameter.shared_config[key].arn
      }
    ],
    # Sensitive values from Secrets Manager
    [
      for key in keys(data.aws_secretsmanager_secret.shared_secrets) : {
        name      = key
        valueFrom = data.aws_secretsmanager_secret.shared_secrets[key].arn
      }
    ],
    # Database passwords from database modules
    [
      for key in keys(data.aws_secretsmanager_secret.database_secrets) : {
        name      = key
        valueFrom = data.aws_secretsmanager_secret.database_secrets[key].arn
      }
    ]
  )

  # Pass dynamic connection strings as environment variables
  environment_variables = [
    for key, value in local.dynamic_connections : {
      name  = key
      value = value
    }
  ]
}

# #############################################################################

module "freeswitch" {
  source                         = "./modules/free-switch"
  app_name                       = local.app_name_freeswitch #var.app_name_freeswitch
  vpc_id                         = data.aws_vpc.optus-vpc.id
  alb_subnets                    = var.alb_subnets
  sbc_fs_subnets = var.sbc_fs_subnets
  ecs_cluster                    = data.aws_ecs_cluster.existing.cluster_name
  kamailio_nlb_security_group_id = module.sbc-kamailio.kamailio_nlb_security_group_id
  vpc_cidr_block                 = data.aws_vpc.optus-vpc.cidr_block
  s3_bucket_name                 = data.aws_s3_bucket.lab_mozart_artifacts_bkt.bucket
  mozart_server                  = module.mozart-voicemail.mozart_voicemail_alb_name
  capacity_provider_name         = local.kamailio_ec2_capacity_provider_name
  #capacity_provider_name         = module.sbc-kamailio.kamailio_ec2_capacity_provider_name
  depends_on = [module.sbc-kamailio]
  # Remove fs_subnets - using shared capacity provider from SBC/kamailio
  # fs_subnets  = var.fs_subnets
}

#############################################################################

module "imap" {
  source                               = "./modules/imap"
  app_name                             = local.app_name_imap #var.app_name_imap
  vpc_id                               = data.aws_vpc.optus-vpc.id
  ecs_cluster                          = data.aws_ecs_cluster.existing.cluster_name
  config_prefix                        = local.config_prefix
  lb_subnet1_cidr_block                = data.aws_subnet.lb_subnet1.cidr_block
  lb_subnet2_cidr_block                = data.aws_subnet.lb_subnet2.cidr_block
  voicemail_ec2_capacity_provider_name = local.voicemail_ec2_capacity_provider_name
  kamailio_ec2_capacity_provider_name  = local.kamailio_ec2_capacity_provider_name
  imap_subnets = var.imap_subnets
  alb_subnets                    = var.alb_subnets
  depends_on                           = [module.mozart-voicemail]

  # Pass shared configuration and secrets to the module
  secrets = concat(
    # Non-sensitive parameters from SSM Parameter Store
    [
      for key in keys(data.aws_ssm_parameter.shared_config) : {
        name      = key
        valueFrom = data.aws_ssm_parameter.shared_config[key].arn
      }
    ],
    # Sensitive values from Secrets Manager
    [
      for key in keys(data.aws_secretsmanager_secret.shared_secrets) : {
        name      = key
        valueFrom = data.aws_secretsmanager_secret.shared_secrets[key].arn
      }
    ],
    # Database passwords from database modules
    [
      for key in keys(data.aws_secretsmanager_secret.database_secrets) : {
        name      = key
        valueFrom = data.aws_secretsmanager_secret.database_secrets[key].arn
      }
    ]
  )

  # Pass dynamic connection strings as environment variables
  environment_variables = [
    for key, value in local.dynamic_connections : {
      name  = key
      value = value
    }
  ]
}

#############################################################################
module "worker" {
  source                               = "./modules/mozart-worker"
  app_name                             = local.app_name_worker #var.app_name_worker
  vpc_id                               = data.aws_vpc.optus-vpc.id
  ecs_cluster                          = data.aws_ecs_cluster.existing.cluster_name
  vpc_cidr_block                       = data.aws_vpc.optus-vpc.cidr_block
  voicemail_ec2_capacity_provider_name = local.voicemail_ec2_capacity_provider_name
  kamailio_ec2_capacity_provider_name  = local.kamailio_ec2_capacity_provider_name
  imap_ec2_capacity_provider_name      = local.imap_ec2_capacity_provider_name
  worker_subnets = var.worker_subnets
  depends_on                           = [module.imap]

  #config_prefix = var.config_prefix

  # Pass shared configuration and secrets to the module
  secrets = concat(
    # Non-sensitive parameters from SSM Parameter Store
    [
      for key in keys(data.aws_ssm_parameter.shared_config) : {
        name      = key
        valueFrom = data.aws_ssm_parameter.shared_config[key].arn
      }
    ],
    # Sensitive values from Secrets Manager
    [
      for key in keys(data.aws_secretsmanager_secret.shared_secrets) : {
        name      = key
        valueFrom = data.aws_secretsmanager_secret.shared_secrets[key].arn
      }
    ],
    # Database passwords from database modules
    [
      for key in keys(data.aws_secretsmanager_secret.database_secrets) : {
        name      = key
        valueFrom = data.aws_secretsmanager_secret.database_secrets[key].arn
      }
    ]
  )

  # Pass dynamic connection strings as environment variables
  environment_variables = [
    for key, value in local.dynamic_connections : {
      name  = key
      value = value
    }
  ]

}

# #############################################################################

module "admin-dashboard" {
  source            = "./modules/admin-dashboard"
  app_name          = local.app_name_admin_dashboard #var.app_name_admin_dashboard
  vpc_id            = data.aws_vpc.optus-vpc.id
  ecs_cluster       = data.aws_ecs_cluster.existing.cluster_name
  config_prefix     = local.config_prefix
  vpc_cidr_block    = data.aws_vpc.optus-vpc.cidr_block
  capacity_provider = local.voicemail_ec2_capacity_provider_name
  voicemail_admin_dashboard_subnets = var.voicemail_admin_dashboard_subnets
  alb_subnets                    = var.alb_subnets
  depends_on        = [module.mozart-voicemail]

  # Pass shared configuration and secrets to the module
  secrets = concat(
    # Non-sensitive parameters from SSM Parameter Store
    [
      for key in keys(data.aws_ssm_parameter.shared_config) : {
        name      = key
        valueFrom = data.aws_ssm_parameter.shared_config[key].arn
      }
    ],
    # Sensitive values from Secrets Manager
    [
      for key in keys(data.aws_secretsmanager_secret.shared_secrets) : {
        name      = key
        valueFrom = data.aws_secretsmanager_secret.shared_secrets[key].arn
      }
    ],
    # Database passwords from database modules
    [
      for key in keys(data.aws_secretsmanager_secret.database_secrets) : {
        name      = key
        valueFrom = data.aws_secretsmanager_secret.database_secrets[key].arn
      }
    ]
  )

  # Pass dynamic connection strings as environment variables
  environment_variables = [
    for key, value in local.dynamic_connections : {
      name  = key
      value = value
    }
  ]
}

#############################################################################

module "smpp" {
  source                     = "./modules/smpp"
  app_name                   = local.app_name_smpp #var.app_name_smpp
  vpc_id                     = data.aws_vpc.optus-vpc.id
  ecs_cluster                = data.aws_ecs_cluster.existing.cluster_name
  config_prefix              = local.config_prefix
  lb_subnet1_cidr_block      = data.aws_subnet.lb_subnet1.cidr_block
  lb_subnet2_cidr_block      = data.aws_subnet.lb_subnet2.cidr_block
  capacity_provider_for_smpp = local.capacity_provider_smpp
  imap_subnets               = var.imap_subnets
  depends_on                 = [module.imap]
  # Pass shared configuration and secrets to the module
  secrets = concat(
    # Non-sensitive parameters from SSM Parameter Store
    [
      for key in keys(data.aws_ssm_parameter.shared_config) : {
        name      = key
        valueFrom = data.aws_ssm_parameter.shared_config[key].arn
      }
    ],
    # Sensitive values from Secrets Manager
    [
      for key in keys(data.aws_secretsmanager_secret.shared_secrets) : {
        name      = key
        valueFrom = data.aws_secretsmanager_secret.shared_secrets[key].arn
      }
    ],
    # Database passwords from database modules
    [
      for key in keys(data.aws_secretsmanager_secret.database_secrets) : {
        name      = key
        valueFrom = data.aws_secretsmanager_secret.database_secrets[key].arn
      }
    ]
  )

  # Pass dynamic connection strings as environment variables
  environment_variables = [
    for key, value in local.dynamic_connections : {
      name  = key
      value = value
    }
  ]
}

#############################################################################

#############################################################################

# # ECS Services Cleanup Resource
# # This resource runs cleanup script before destroying ECS infrastructure
# resource "null_resource" "ecs_services_cleanup" {
#   triggers = {
#     cluster_name = data.aws_ecs_cluster.existing.cluster_name
#   }

#   # Cleanup script execution on destroy
#   provisioner "local-exec" {
#     when    = destroy
#     command = <<-EOT
#       #!/bin/bash
#       set -e
      
#       export AWS_PROFILE="Optus"
#       CLUSTER_NAME="${self.triggers.cluster_name}"
      
#       echo "Starting ECS services cleanup for cluster: $$CLUSTER_NAME"
      
#       # Get service names using AWS CLI query (no jq required)
#       mapfile -t SERVICE_NAMES < <(aws ecs list-services --cluster $$CLUSTER_NAME --query 'serviceArns[*]' --output text | xargs -n1 | sed 's|.*/||')
      
#       if [ $${#SERVICE_NAMES[@]} -eq 0 ]; then
#           echo "No services found in cluster"
#           exit 0
#       fi
      
#       echo "Found $${#SERVICE_NAMES[@]} services: $${SERVICE_NAMES[*]}"
      
#       # Stop all services
#       echo ""
#       echo "Stopping all services..."
#       for service in "$${SERVICE_NAMES[@]}"; do
#           echo "  Stopping service: $$service"
#           aws ecs update-service --cluster $$CLUSTER_NAME --service $$service --desired-count 0 >/dev/null 2>&1
#           if [ $$? -eq 0 ]; then
#               echo "    Successfully stopped"
#           else
#               echo "    Failed to stop"
#           fi
#       done
      
#       # Wait for services to drain
#       echo ""
#       echo "Waiting for services to drain..."
#       sleep 60
      
#       # Delete all services
#       echo ""
#       echo "Deleting all services..."
#       for service in "$${SERVICE_NAMES[@]}"; do
#           echo "  Deleting service: $$service"
#           aws ecs delete-service --cluster $$CLUSTER_NAME --service $$service --force >/dev/null 2>&1
#           if [ $$? -eq 0 ]; then
#               echo "    Successfully deleted"
#           else
#               echo "    Failed to delete"
#           fi
#       done
      
#       # Wait a bit more for complete cleanup
#       echo ""
#       echo "Waiting for complete cleanup..."
#       sleep 30
      
#       # Clear capacity provider strategies
#       echo ""
#       echo "Clearing capacity provider strategies from cluster..."
#       aws ecs put-cluster-capacity-providers \
#           --cluster $$CLUSTER_NAME \
#           --capacity-providers [] \
#           --default-capacity-provider-strategy [] >/dev/null 2>&1
      
#       if [ $$? -eq 0 ]; then
#           echo "Successfully cleared capacity provider strategies"
#       else
#           echo "Failed to clear capacity provider strategies (may not exist)"
#       fi
      
#       echo "Cleanup complete - processed $${#SERVICE_NAMES[@]} services"
#     EOT

#     interpreter = ["/bin/bash", "-c"]
#   }

#   # Dependencies - this resource should be destroyed BEFORE the modules
#   depends_on = [
#     module.imap,
#     module.worker,
#     module.smpp,
#     module.sbc-kamailio,
#     module.mozart-voicemail,
#     module.freeswitch,
#     module.admin-dashboard
#   ]
# }
# # End of ECS Services Cleanup Resource