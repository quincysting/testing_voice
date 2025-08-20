terraform {
  backend "s3" {
    bucket         = "optus-terraform-state-607570804706"
    key            = "optus-ecs-lab/terraform.tfstate"
    region         = "ap-southeast-2"
    # dynamodb_table = "terraform-state"
    encrypt        = true

    assume_role = {
      role_arn = "arn:aws:iam::607570804706:role/terraform-state-mgmt"
    }
  }
}

