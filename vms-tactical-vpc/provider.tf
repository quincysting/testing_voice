provider "aws" {
  region = "ap-southeast-2"

  assume_role {
    role_arn = "arn:aws:iam::607570804706:role/gitlab-infra-deployment-role"
  }

  default_tags {
    tags = local.tags
  }
}