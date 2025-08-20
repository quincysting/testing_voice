terraform {
  required_version = "~> 1.8"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.46"
    }
  }

  backend "s3" {
    bucket         = "optus-terraform-state-607570804706"
    key            = "vms-tactical-vpc/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "terraform-state"
    encrypt        = true

    assume_role = {
      role_arn = "arn:aws:iam::607570804706:role/terraform-state-mgmt"
    }
  }
}
