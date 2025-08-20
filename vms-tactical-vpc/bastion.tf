locals {
  bastion_name = "norwood-bastion-poc"
}

module "bastion_sg" {
  source = "git::https://optus.gitlab-dedicated.com/Optus/GroupIT/TechFoundations/CDOT/terraform-aws-optus-security-group.git?ref=v1.0.1"

  name        = local.bastion_name
  description = "The security group for ${local.bastion_name}"
  vpc_id      = module.vms_tactical.vpc_id

  egress_rules = ["all-all"]

  tags = merge(local.tags, {
    Name = local.bastion_name
  })
}

module "bastion_instance" {
  source = "git::https://optus.gitlab-dedicated.com/Optus/GroupIT/TechFoundations/CDOT/terraform-aws-optus-ec2-instance?ref=v1.1.0"

  name = local.bastion_name

  ami                    = "ami-0659993d6798a2c92" # al2023-soe-20250617082843
  instance_type          = "t3.micro"
  availability_zone      = "ap-southeast-2a"
  subnet_id              = module.vms_tactical.subnets["utility-2a"].id
  vpc_security_group_ids = [module.bastion_sg.security_group_id]

  iam_instance_profile = aws_iam_instance_profile.bastion.name

  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  root_block_device = [
    {
      encrypted   = true
      volume_type = "gp3"
      volume_size = 50
    },
  ]

  tags = merge(local.tags, {
    Name                       = local.bastion_name
    SSM-SessionManager-Norwood = "Allowed"
    }
  )
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${local.bastion_name}-profile"

  role = "gitlab-app-deployment-role"

  tags = merge(local.tags, {
    Name = "${local.bastion_name}-profile"
  })
}