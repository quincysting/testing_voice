data "aws_launch_template" "existing" {
  filter {
    name   = "tag:Name"
    values = ["mozart-${local.env}-launch_template"]
  }
}

data "aws_ecs_cluster" "existing" {
  cluster_name = "mozart-${local.env}-cluster"
}


# SSM parameters and secrets are now managed in shared-config.tf
# This provides centralized configuration management

data "aws_s3_bucket" "lab_mozart_artifacts_bkt" {
  bucket = "${local.env}-mozart-assets-bucket"
}

data "aws_ecr_repository" "admin_dashboard_ecr" {
  name = "admin-dashboard"
}


data "aws_subnet" "lb_subnet1" {
  id = var.lb_subnet1
}

data "aws_subnet" "lb_subnet2" {
  id = var.lb_subnet2
}

# Data sources for RDS, ElastiCache, and secrets moved to shared-config.tf
# for dynamic connection string construction