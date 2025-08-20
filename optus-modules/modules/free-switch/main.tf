# ====================== Fixed Freeswitch resources =========================

# Create SSM parameters for Freeswitch configuration
resource "aws_ssm_parameter" "freeswitch_config" {
  for_each = {
    # Non-sensitive environment variables for freeswitch container
    "PATH"           = "/usr/local/freeswitch/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    "GATEWAY"        = "198.199.100.45"
    "VM_MAX_WORKERS" = "16"
    # "MOZART_SERVER" = "http://mozart-alb-1142825309.ap-southeast-2.elb.amazonaws.com"
    # "MOZART_SERVER" = "http://${module.mozart-voicemail.mozart_voicemail_alb_name}"
    "MOZART_SERVER" = var.mozart_server
    #UPLOAD_TO_MOZART = "http://${module.mozart-voicemail.mozart_voicemail_alb_name}" #"mozart-voicemail load balancer dns"
    UPLOAD_MEDIA_BUCKET = var.s3_bucket_name #  "s3 bucket name we configured"
    #UPLOAD_MEDIA_SERVER = "s3-ap-southeast-2.amazonaws.com"
    "AFFINITY"            = "Freeswitch"
    "UPLOAD_MEDIA_SERVER" = "s3-ap-southeast-2.amazonaws.com"
    "LD_LIBRARY_PATH"     = "/usr/local/src/freeswitch/libs/speechsdk/lib/x64"
    #"UPLOAD_MEDIA_BUCKET"   = "mozart-assets-bucket"
    "UPLOAD_TO_MOZART" = "YES"
    "DELETE_LOCAL_VM"  = "NO"
  }

  name        = "/${var.app_name}/${each.key}"
  description = "Freeswitch application configuration parameter"
  type        = "String"
  value       = each.value

  tags = {
    Name = "${var.app_name}-${each.key}"
  }
}

#Get all secrets from AWS Secrets Manager
data "aws_secretsmanager_secrets" "all" {}

locals {
  all_secret_pairs = flatten([
    for name in tolist(data.aws_secretsmanager_secrets.all.names) : [
      for arn in tolist(data.aws_secretsmanager_secrets.all.arns) : {
        name = name
        arn  = arn
      } if endswith(arn, name)
    ]
  ])

  lab_secrets = [
    for s in local.all_secret_pairs : s
    if can(regex("freeswitch", lower(s.name))) && s.arn != null && s.arn != ""
  ]
}

resource "aws_iam_policy" "freeswitch_secrets_access" {
  name        = "${var.app_name}-secrets-access"
  description = "Allow Freeswitch ECS tasks to access Secrets Manager"

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

resource "aws_security_group" "freeswitch_nlb" {
  name        = "${var.app_name}-nlb-sg"
  description = "Allow SIP traffic for Freeswitch server"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "udp"
    from_port   = 6060
    to_port     = 6060
    cidr_blocks = [var.vpc_cidr_block] # Restrict to VPC CIDR block, to be refined once subnets information is available
  }

  ingress {
    protocol    = "tcp"
    from_port   = 6060
    to_port     = 6060
    cidr_blocks = [var.vpc_cidr_block] # Restrict to VPC CIDR block, to be refined once subnets information is available
  }

  ingress {
    protocol    = "tcp"
    from_port   = 5060
    to_port     = 5060
    cidr_blocks = [var.vpc_cidr_block] # Restrict to VPC CIDR block, to be refined once subnets information is available
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-nlb-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "freeswitch" {
  name               = trim(substr("${var.app_name}-nlb", 0, 32), "-")
  internal           = true
  load_balancer_type = "network"
  security_groups    = [aws_security_group.freeswitch_nlb.id]
  subnets            = var.alb_subnets

  tags = {
    Name = "${var.app_name}-nlb"
  }
}


resource "aws_security_group" "freeswitch" {
  name        = "${var.app_name}-sg"
  description = "Allow inbound access from the NLB only for freeswitch server"
  vpc_id      = var.vpc_id

  ingress {
    protocol        = "udp"
    from_port       = 6060
    to_port         = 6060
    security_groups = [var.kamailio_nlb_security_group_id, aws_security_group.freeswitch_nlb.id]
  }

  ingress {
    protocol        = "tcp"
    from_port       = 6060
    to_port         = 6060
    security_groups = [var.kamailio_nlb_security_group_id, aws_security_group.freeswitch_nlb.id]
  }

  ingress {
    protocol    = "udp"
    from_port   = 6060
    to_port     = 6060
    cidr_blocks = [var.vpc_cidr_block] # Restrict to VPC CIDR block, to be refined once subnets information is available
  }

  ingress {
    protocol    = "tcp"
    from_port   = 6060
    to_port     = 6060
    cidr_blocks = [var.vpc_cidr_block] # Restrict to VPC CIDR block, to be refined once subnets information is available
  }

  ingress {
    protocol        = "tcp"
    from_port       = 5060
    to_port         = 5060
    security_groups = [aws_security_group.freeswitch_nlb.id]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 5060
    to_port     = 5060
    cidr_blocks = [var.vpc_cidr_block] # Restrict to VPC CIDR block, to be refined once subnets information is available
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-sg"
  }
}

resource "aws_lb_target_group" "freeswitch" {
  name        = trim(substr("${var.app_name}-tgt-grp", 0, 32), "-")
  port        = 6060
  protocol    = "UDP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    protocol            = "TCP" # TCP health check for SIP service
    port                = 5060  # Use SIP port which accepts TCP connections
    healthy_threshold   = 2     # Reduced from 3 for faster recovery
    unhealthy_threshold = 2     # Reduced from 3 for faster detection
    timeout             = 10    # Reduced from 30 seconds
    interval            = 30    # Reduced from 60 seconds
  }

  tags = {
    Name = "${var.app_name}-target-group"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "freeswitch" {
  load_balancer_arn = aws_lb.freeswitch.arn
  port              = 6060
  protocol          = "UDP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.freeswitch.arn
  }
}

# TCP target group for health checks on port 5060
resource "aws_lb_target_group" "freeswitch_health" {
  name        = trim(substr("${var.app_name}-health-tg", 0, 32), "-")
  port        = 5060
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    protocol            = "TCP"
    port                = 5060
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 10
    interval            = 30
  }

  tags = {
    Name = "${var.app_name}-health-tg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# TCP listener for health checks on port 5060
resource "aws_lb_listener" "freeswitch_health" {
  load_balancer_arn = aws_lb.freeswitch.arn
  port              = 5060
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.freeswitch_health.arn
  }
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.app_name}-ec2-instance-profile"
  role = aws_iam_role.ec2_instance_role.name
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role_policy" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role" "ec2_instance_role" {
  name = "${var.app_name}-ec2-instance-role"

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

resource "aws_ecs_task_definition" "freeswitch" {
  family                   = "${var.app_name}-task-new"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  execution_role_arn       = aws_iam_role.freeswitch_execution_role.arn
  task_role_arn            = aws_iam_role.freeswitch_task_role.arn
  cpu                      = 2048
  memory                   = 3096

  container_definitions = jsonencode([{
    name  = "${var.app_name}"
    image = "607570804706.dkr.ecr.ap-southeast-2.amazonaws.com/freeswitch-optus-voicemail:0.8.1"
    essential = true
    command   = ["freeswitch", "-nonat", "-u", "freeswitch", "-g", "daemon"]
    #command = ["/usr/local/freeswitch/bin/freeswitch", "-nonat", "-nf"]
    portMappings = [
      {
        containerPort = 6060
        protocol      = "udp"
      },
      {
        containerPort = 5060
        protocol      = "tcp"
      }
    ]

    # FIXED: Health check options for separate health port
    healthCheck = {
      command = [
        "CMD-SHELL",
        "pgrep freeswitch || exit 1"
        #"netstat -an | grep :5060 || exit 1"
        #"fs_cli -x 'status' || exit 1"
      ]
      interval    = 30
      timeout     = 10
      retries     = 3
      startPeriod = 120
    }

    secrets = concat(
      # Non-sensitive parameters from SSM Parameter Store
      [
        for key in keys(aws_ssm_parameter.freeswitch_config) : {
          name      = key
          valueFrom = aws_ssm_parameter.freeswitch_config[key].arn
        }
      ],
      # Sensitive values from Secrets Manager
      [
        for secret in local.lab_secrets : {
          name      = replace(secret.name, "/", "_") # Replace slashes with underscores for valid env var names
          valueFrom = secret.arn
        }
        if secret.arn != null && secret.arn != ""
      ],
      var.secrets
    )

    environment = concat(var.environment_variables, [
      {
        name  = "FREESWITCH_LOG_LEVEL"
        value = "DEBUG"
      },
      {
        name  = "FREESWITCH_CONSOLE_LOG_LEVEL"
        value = "DEBUG"
      }
    ])

  }])
}


resource "aws_ecs_service" "freeswitch" {
  name            = "${var.app_name}-service"
  cluster         = var.ecs_cluster
  task_definition = aws_ecs_task_definition.freeswitch.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = var.capacity_provider_name
    weight            = 100
    base              = 1
  }

  network_configuration {
    security_groups  = [aws_security_group.freeswitch.id]
    subnets          = var.sbc_fs_subnets
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.freeswitch.arn
    container_name   = var.app_name
    container_port   = 6060
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.freeswitch_health.arn
    container_name   = var.app_name
    container_port   = 5060
  }

  lifecycle {
    ignore_changes = [task_definition]
  }

  depends_on = [
    aws_lb_listener.freeswitch,
    aws_lb_listener.freeswitch_health
  ]

  tags = {
    Name = "${var.app_name}-service"
  }
}

# resource "aws_ecs_service" "freeswitch" {
#   name            = "${var.app_name}-service"
#   cluster         = var.ecs_cluster
#   task_definition = aws_ecs_task_definition.freeswitch.arn
#   desired_count   = 1

#   capacity_provider_strategy {
#     capacity_provider = var.capacity_provider_name
#     weight            = 100
#     base              = 1
#   }

#   network_configuration {
#     security_groups  = [aws_security_group.freeswitch.id]
#     subnets          = var.fs_subnets
#     assign_public_ip = false
#   }

#   load_balancer {
#     target_group_arn = aws_lb_target_group.freeswitch.arn
#     container_name   = "${var.app_name}"
#     container_port   = 6060
#   }

#   # Additional load balancer for health checks
#   load_balancer {
#     target_group_arn = aws_lb_target_group.freeswitch_health.arn
#     container_name   = "${var.app_name}"
#     container_port   = 5060
#   }

#   lifecycle {
#     ignore_changes = [task_definition]
#   }

#   depends_on = [aws_lb_listener.freeswitch]

#   tags = {
#     Name = "${var.app_name}-service"
#   }
# }

# Supporting Resources
resource "aws_iam_role" "freeswitch_execution_role" {
  name = "ecs-${var.app_name}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "freeswitch_secrets_policy" {
  role       = aws_iam_role.freeswitch_execution_role.name
  policy_arn = aws_iam_policy.freeswitch_secrets_access.arn
}

resource "aws_iam_role_policy_attachment" "freeswitch_execution_role_policy" {
  role       = aws_iam_role.freeswitch_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "freeswitch_task_role" {
  name = "ecs-${var.app_name}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}



#========================= The end of Freeswitch resources ===================
