provider "aws" {
  region  = "ap-southeast-2"

  assume_role {
    role_arn = "arn:aws:iam::607570804706:role/gitlab-app-deployment-role"
  }

  default_tags {
    tags = {
      o_b_bu         = "networks"
      o_b_pri-own    = "Alfred Lam"
      o_b_bus-own    = "James Burden"
      o_t_app-plat   = "networks"
      o_t_app        = "voicemail"
      o_t_env        = "poc"
      o_t_app-own    = "Brian Easson"
      o_t_tech-own   = "Serena Feng"
      o_b_cc         = "gk881infra"
      o_s_app-class  = "cat2"
      o_b_project    = "VMS"
      o_s_data-class = "conf_non_pii"
      o_t_app-role   = "app"
      o_a_avail      = "24x7"
      o_s_sra        = "00642"
      o_t_dep-mthd   = "hybrid"
      o_t_lifecycle  = "inbuild"
    }
  }
}


# Secrets are managed by optus-scripts instead of Terraform

# SSM parameters are managed by optus-scripts instead of Terraform

# DB password is managed by optus-scripts instead of Terraform

# data "aws_secretsmanager_secret_version" "rds_password" {
#  secret_id = module.aurora_rds.password_secret_arn
#}

locals {
  #env = "lab"
  env = "tactical-lab" 
}

module "aurora_rds" {
  source   = "./modules/aurora_rds"
  app_name = "mozart-db-${local.env}"
}

module "kamailio_rds" {
  source   = "./modules/kamailio_rds"
  app_name = "kamailio-db-${local.env}"
}

import {
  to = module.elasticache.aws_elasticache_replication_group.redis
  id = "mozart-redis-tactical-lab"
}

module "elasticache" {
  source   = "./modules/elasticache"
  app_name = "mozart-redis-${local.env}"
}
