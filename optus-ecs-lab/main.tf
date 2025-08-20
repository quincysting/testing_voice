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

locals {
  #environment = "lab"
  environment = "tactical-lab"
}

resource "aws_ecs_cluster" "ecs_lab" {
  name = "mozart-${local.environment}-cluster"

  tags = {
    Name = "mozart-${local.environment}-cluster"
  }
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "mozart-${local.environment}-ec2-instance-profile"
  role = aws_iam_role.ec2_instance_role.name
}

resource "aws_launch_template" "ecs_lab" {
  name_prefix   = "mozart-${local.environment}-ecs-lt"
  image_id      = data.aws_ami.ecs_optimized.id
  instance_type = "t3.medium"
  # security_groups      = [aws_security_group.instance.id]
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }
  key_name = null
  user_data = base64encode(<<-EOF
                          #!/bin/bash
                          echo ECS_CLUSTER=${aws_ecs_cluster.ecs_lab.name} >> /etc/ecs/ecs.config
                          EOF
  )

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "mozart-${local.environment}-launch_template"
  }

}

data "aws_ami" "ecs_optimized" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_ecs_cluster_capacity_providers" "example" {
  cluster_name = aws_ecs_cluster.ecs_lab.name

  # to created as part of optus-modules 
  # capacity_providers = [
  #   module.sbc.kamailio_ec2_capacity_provider_name,
  #   module.mozart-voicemail.voicemail_ec2_capacity_provider_name
  #   ]

  #default_capacity_provider_strategy {
  #  base              = 1
  #  weight            = 100
  #  capacity_provider = " "
  #}
  # depends_on = [
  #   module.sbc, 
  #   module.mozart-voicemail
  # ]
}

# Add a custom policy for additional EC2 permissions
resource "aws_iam_role_policy" "ec2_instance_additional_policy" {
  name = "mozart-${local.environment}-ec2-additional-policy"
  role = aws_iam_role.ec2_instance_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "ssm:GetParameters",
          "ssm:GetParameter",
          "ssm:DescribeParameters"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_role" "ec2_instance_role" {
  name = "mozart-${local.environment}-ec2-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "mozart-${local.environment}-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Add permissions for Secrets Manager
resource "aws_iam_policy" "secrets_manager_access" {
  name        = "mozart-${local.environment}-secrets-manager-access"
  description = "Allow ECS tasks in LAB env to access Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "ssm:GetParameters",
          "ssm:GetParameter",
          "ssm:DescribeParameters"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_secrets_manager_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.secrets_manager_access.arn
}

resource "aws_iam_role" "ecs_task_role" {
  name = "mozart-${local.environment}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_role_secrets_manager_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.secrets_manager_access.arn
}


resource "aws_iam_role_policy_attachment" "ec2_instance_role_policy" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

#### S3 resources and policies

# S3 Bucket for Mozart application artifacts
resource "aws_s3_bucket" "mozart_artifacts" {
  bucket = "${local.environment}-mozart-assets-bucket"

  tags = {
    Name        = "${local.environment}-mozart-assets-bucket"
    Application = "Mozart"
  }
}

resource "aws_s3_bucket_public_access_block" "mozart_artifacts_public_access" {
  bucket = aws_s3_bucket.mozart_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "mozart_artifacts_versioning" {
  bucket = aws_s3_bucket.mozart_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

# IAM Policy for Mozart services to access the S3 bucket
resource "aws_iam_policy" "mozart_s3_access_policy" {
  name        = "MozartS3AccessPolicy-${local.environment}"
  description = "Allows Mozart services to access the S3 artifact bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.mozart_artifacts.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:DeleteObjectVersion" # Required for versioned buckets
        ]
        Resource = [
          "${aws_s3_bucket.mozart_artifacts.arn}/*"
        ]
      }
    ]
  })
}


# data "aws_ssm_parameter" "app_config" {
#   for_each = local.ssm_parameters
#   name     = each.value
# }

# # Fetch each secret
# data "aws_secretsmanager_secret_version" "secrets" {
#   for_each  = local.secret_arns
#   secret_id = each.value
# }

# # Extract values into a usable map
# locals {
#   secret_values = {
#     for key, secret in data.aws_secretsmanager_secret_version.secrets :
#     key => secret.secret_string
#   }
# }
